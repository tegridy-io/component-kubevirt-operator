// main template for kubevirt-operator
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local olm = import 'lib/olm.libsonnet';

local helper = import 'helper.libsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local operator = inv.parameters.kubevirt_operator.operators.hyperconverged;
local params = inv.parameters.kubevirt_operator.config;
local isOpenshift = std.startsWith(inv.parameters.facts.distribution, 'openshift');

// Namespace
local namespace = kube.Namespace('kubevirt-hyperconverged') {
  metadata+: {
    annotations+: operator.namespace.annotations,
    labels+: {
      // Configure the namespaces so that the OCP4 cluster-monitoring
      // Prometheus can find the servicemonitors and rules.
      [if isOpenshift then 'openshift.io/cluster-monitoring']: 'true',
    } + com.makeMergeable(operator.namespace.labels),
  },
};

// OLM
local packageName = if isOpenshift then 'kubevirt-hyperconverged' else 'community-kubevirt-hyperconverged';
local catalog = if isOpenshift then 'redhat-operators' else 'operatorhubio-catalog';

local operatorGroup = olm.OperatorGroup('kubevirt-operators') {
  metadata+: {
    namespace: 'kubevirt-hyperconverged',
  },
};

local subscription = olm.namespacedSubscription(
  'kubevirt-hyperconverged',
  packageName,
  operator.channel,
  catalog,
) {
  spec+: {
    config+: {
      resources: operator.resources,
    },
  },
};

// Instance
local config = com.makeMergeable(params.scale)
               + com.makeMergeable(params.quota)
               + com.makeMergeable(params.hostpath)
               + com.makeMergeable(params.network)
               + com.makeMergeable(params.importer)
               + com.makeMergeable(params.kubevirt);

local instance = kube._Object('hco.kubevirt.io/v1beta1', 'HyperConverged', 'instance') {
  metadata+: {
    labels: {
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': 'instance',
      'app.kubernetes.io/instance': 'instance',
    },
    namespace: 'kubevirt-hyperconverged',
  },
  spec: config,
};


// Define outputs below
if helper.isEnabled('hyperconverged') then {
  '00_namespace': namespace,
  '10_operator_group': operatorGroup,
  '10_subscription': subscription,
  [if std.length(config) > 0 then '20_instance']: instance,
} else {}
