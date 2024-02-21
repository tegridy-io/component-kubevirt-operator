// main template for kubevirt-operator
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local helper = import 'helper.libsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator.operators.kubevirt;
local isOpenshift = std.startsWith(inv.parameters.facts.distribution, 'openshift');

// Namespace
local namespace = kube.Namespace(params.namespace.name) {
  metadata+: {
    annotations+: params.namespace.annotations,
    labels+: {
      // Configure the namespaces so that the OCP4 cluster-monitoring
      // Prometheus can find the servicemonitors and rules.
      [if isOpenshift then 'openshift.io/cluster-monitoring']: 'true',
    } + com.makeMergeable(params.namespace.labels),
  },
};

// Instance
local instance = kube._Object('kubevirt.io/v1', 'KubeVirt', 'instance') {
  metadata+: {
    labels: {
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': 'instance',
      'app.kubernetes.io/instance': 'instance',
    },
    namespace: params.namespace.name,
  },
  spec: inv.parameters.kubevirt_operator.kubevirt,
};

// Define outputs below
if params.enabled then
  {
    '00_namespace': namespace,
    '10_bundle': helper.load('kubevirt-%s/kubevirt-operator.yaml' % params.version, params.namespace.name),
    '20_instance': instance,
  }
