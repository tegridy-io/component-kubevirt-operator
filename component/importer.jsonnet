// main template for kubevirt-operator
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local helper = import 'helper.libsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local operator = inv.parameters.kubevirt_operator.operators.importer;
local config = inv.parameters.kubevirt_operator.config.importer;

// Namespace
local namespace = kube.Namespace(operator.namespace.name) {
  metadata+: {
    annotations+: operator.namespace.annotations,
    labels+: {
      // Configure the namespaces so that the OCP4 cluster-monitoring
      // Prometheus can find the servicemonitors and rules.
      [if helper.isOpenshift then 'openshift.io/cluster-monitoring']: 'true',
    } + com.makeMergeable(operator.namespace.labels),
  },
};

// Instance
local instance = kube._Object('cdi.kubevirt.io/v1beta1', 'CDI', 'instance') {
  metadata+: {
    labels: {
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': 'instance',
      'app.kubernetes.io/instance': 'instance',
    },
    namespace: operator.namespace.name,
  },
  spec: config,
};

// Define outputs below
if helper.hasImporter then
  {
    '00_namespace': namespace,
    '10_bundle': helper.load('cdi-%s/cdi-operator.yaml' % operator.version, operator.namespace.name),
    '20_instance': instance,
  } else {
  '20_instance': instance,
}
