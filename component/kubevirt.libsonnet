// main template for kubevirt-operator
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local helper = import 'helper.libsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local namespace = inv.parameters.kubevirt_operator.namespace;
local operator = inv.parameters.kubevirt_operator.operators.kubevirt;
local config = inv.parameters.kubevirt_operator.config.kubevirt;
local cluster = inv.parameters.kubevirt_operator.cluster;

// KubeVirt
local instance = kube._Object('kubevirt.io/v1', 'KubeVirt', 'instance') {
  metadata+: {
    labels: {
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': 'instance',
      'app.kubernetes.io/instance': 'instance',
    },
    namespace: namespace.name,
  },
  spec: config,
};

// VirtualMachineClusterInstancetype
local type(name) = kube._Object('instancetype.kubevirt.io/v1beta1', 'VirtualMachineClusterInstancetype', name) {
  metadata+: {
    labels+: {
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': name,
    },
  },
  spec+: cluster.types[name],
};

// VirtualMachineClusterPreference
local preference(name) = kube._Object('instancetype.kubevirt.io/v1beta1', 'VirtualMachineClusterPreference', name) {
  metadata+: {
    labels+: {
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': name,
    },
  },
  spec+: cluster.preferences[name],
};

// Define outputs below
{
  bundle: helper.load('kubevirt-%s/kubevirt-operator.yaml' % operator.version, namespace.name),
  instance: instance,
  type: type,
  preference: preference,
}
