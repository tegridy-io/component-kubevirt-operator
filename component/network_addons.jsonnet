// main template for kubevirt-operator
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local helper = import 'helper.libsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local operator = inv.parameters.kubevirt_operator.operators.network_addons;
local config = inv.parameters.kubevirt_operator.config.network_addons;
local isOpenshift = std.startsWith(inv.parameters.facts.distribution, 'openshift');

// Namespace
local namespace = kube.Namespace(operator.namespace.name) {
  metadata+: {
    annotations+: operator.namespace.annotations,
    labels+: {
      // Configure the namespaces so that the OCP4 cluster-monitoring
      // Prometheus can find the servicemonitors and rules.
      [if isOpenshift then 'openshift.io/cluster-monitoring']: 'true',
    } + com.makeMergeable(operator.namespace.labels),
  },
};

// Bundle
local bundle = helper.load('cna-%s/crd.yaml' % operator.version, operator.namespace.name)
               + helper.load('cna-%s/operator.yaml' % operator.version, operator.namespace.name);

// Instance
local instance = kube._Object('networkaddonsoperator.network.kubevirt.io/v1', 'NetworkAddonsConfig', 'instance') {
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
if helper.isEnabled('importer') then {
  '30_network_addons/00_namespace': namespace,
  '30_network_addons/10_bundle': bundle,
  [if std.length(config) > 0 then '30_network_addons/20_instance']: instance,
} else {}
