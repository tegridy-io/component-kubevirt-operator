// main template for kubevirt-operator
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local helper = import 'helper.libsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator;
local isOpenshift = std.startsWith(inv.parameters.facts.distribution, 'openshift');

// Namespace
// local namespace = kube.Namespace(params.namespace.name) {
//   metadata+: {
//     annotations+: params.namespace.annotations,
//     labels+: {
//       // Configure the namespaces so that the OCP4 cluster-monitoring
//       // Prometheus can find the servicemonitors and rules.
//       [if isOpenshift then 'openshift.io/cluster-monitoring']: 'true',
//     } + com.makeMergeable(params.namespace.labels),
//   },
// };

// Instance

// Define outputs below
{
  [if helper.isEnabled('hostpath_provisioner') then '40_hostpath_provisioner/10_bundle']: helper.load('hpp-%s/operator.yaml' % params.operators.hostpath_provisioner.version, params.operators.hostpath_provisioner.namespace.name),
  [if std.length(params.config.hostpath_provisioner) > 0 then '40_hostpath_provisioner/20_instance']: helper.instance('hostpath_provisioner', params.operators.hostpath_provisioner.namespace.name),
}
// if helper.isEnabled('importer') then {
//   '20_importer/00_namespace': namespace,
//   '20_importer/10_bundle': helper.load('cdi-%s/cdi-operator.yaml' % operator.version, operator.namespace.name),
//   [if std.length(config) > 0 then '20_importer/20_instance']: instance,
// } else {}
