// main template for kubevirt-operator
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local olm = import 'lib/olm.libsonnet';

local helper = import 'helper.libsonnet';
local importer = import 'importer.libsonnet';
local kubevirt = import 'kubevirt.libsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local ns = inv.parameters.kubevirt_operator.namespace;
local params = inv.parameters.kubevirt_operator;

// Namespace
local namespace = kube.Namespace(params.namespace.name) {
  metadata+: {
    annotations+: params.namespace.annotations,
    labels+: {
      // Configure the namespaces so that the OCP4 cluster-monitoring
      // Prometheus can find the servicemonitors and rules.
      [if helper.isOpenshift then 'openshift.io/cluster-monitoring']: 'true',
    } + com.makeMergeable(params.namespace.labels),
  },
};

// Holdrio
local packageName = if helper.isOpenshift then 'kubevirt-hyperconverged' else 'community-kubevirt-hyperconverged';
local catalog = if helper.isOpenshift then 'redhat-operators' else 'operatorhubio-catalog';

local operatorGroup = olm.OperatorGroup('kubevirt-operators') {
  metadata+: {
    namespace: params.namespace.name,
  },
};

local subscription = olm.namespacedSubscription(
  params.namespace.name,
  packageName,
  params.olm.channel,
  catalog,
) {
  spec+: {
    config+: {
      resources: params.olm.resources,
    },
  },
};

// Define outputs below
{
  '00_namespace': namespace,
  [if helper.kubevirtEnabled && !helper.olmEnabled then '10_kubevirt_bundle']: kubevirt.bundle,
  [if helper.importerEnabled && !helper.olmEnabled then '10_importer_bundle']: importer.bundle,
  // '10_subscription': subscription,
  [if helper.olmEnabled then '10_operator_group']: operatorGroup,
  [if helper.olmEnabled then '10_subscription']: subscription,
  [if helper.kubevirtEnabled then '20_kubevirt_instance']: kubevirt.instance,
  [if helper.importerEnabled then '20_importer_instance']: importer.instance,
  [if helper.kubevirtEnabled then '30_kubevirt_type']: [ kubevirt.type(name) for name in std.objectFields(params.cluster.types)],
  [if helper.kubevirtEnabled then '30_kubevirt_preferences']: [ kubevirt.preference(name) for name in std.objectFields(params.cluster.preferences)],
}
