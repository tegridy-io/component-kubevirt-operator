// main template for kubevirt-operator
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local olm = import 'lib/olm.libsonnet';

local helper = import 'helper.libsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local kubevirt = inv.parameters.kubevirt_operator.operators.kubevirt;
local hyperconverged = inv.parameters.kubevirt_operator.operators.hyperconverged;

local packageName = if helper.isOpenshift then 'kubevirt-hyperconverged' else 'community-kubevirt-hyperconverged';
local catalog = if helper.isOpenshift then 'redhat-operators' else 'operatorhubio-catalog';

local operatorGroup = olm.OperatorGroup('kubevirt-operators') {
  metadata+: {
    namespace: kubevirt.namespace.name,
  },
  spec: {
    targetNamespaces: [
      kubevirt.namespace.name,
    ],
  },
};

local subscription = olm.namespacedSubscription(
  kubevirt.namespace,
  packageName,
  hyperconverged.channel,
  catalog,
) {
  spec+: {
    config+: {
      resources: hyperconverged.resources,
    },
  },
};

// Define outputs below
if helper.hasHyperconverged then
  {
    '00_operator_group': operatorGroup,
    '10_subscription': subscription,
  }
