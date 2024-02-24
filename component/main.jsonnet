// main template for kubevirt-operator
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local olm = import 'lib/olm.libsonnet';

local helper = import 'helper.libsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator;
local isOpenshift = std.startsWith(inv.parameters.facts.distribution, 'openshift');

// Namespace
local namespaceName = if helper.deployOlm then 'kubevirt-hyperconverged'
else params.namespace.name;

local namespace = kube.Namespace(namespaceName) {
  metadata+: {
    annotations+: params.namespace.annotations,
    labels+: {
      'kubevirt.io': '',
      'cdi.kubevirt.io': '',
      'pod-security.kubernetes.io/enforce': 'privileged',
      // Configure the namespaces so that the OCP4 cluster-monitoring
      // Prometheus can find the servicemonitors and rules.
      [if isOpenshift then 'openshift.io/cluster-monitoring']: 'true',
    } + com.makeMergeable(params.namespace.labels),
  },
};

// OLM
local packageName = if isOpenshift then 'kubevirt-hyperconverged' else 'community-kubevirt-hyperconverged';
local catalog = if isOpenshift then 'redhat-operators' else 'operatorhubio-catalog';

local operator_group = olm.OperatorGroup('kubevirt-operators') {
  metadata+: {
    namespace: 'kubevirt-hyperconverged',
  },
};

local subscription = olm.namespacedSubscription(
  'kubevirt-hyperconverged',
  packageName,
  params.olm.channel,
  catalog,
) {
  metadata: {
    name: packageName,
    namespace: 'kubevirt-hyperconverged',
  },
  spec+: {
    config+: {
      resources: params.olm.resources,
    },
  },
};

// Bundles and Instances
local bundle_kubevirt = helper.load('kubevirt-%s/operator.yaml' % params.operators.kubevirt.version, namespaceName);
local bundle_importer = helper.load('cdi-%s/operator.yaml' % params.operators.data_importer.version, namespaceName);
local bundle_network = helper.load('cna-%s/crd.yaml' % params.operators.network_addons.version, namespaceName)
                       + helper.load('cna-%s/operator.yaml' % params.operators.network_addons.version, namespaceName);
local bundle_hostpath = helper.load('hpp-%s/operator.yaml' % params.operators.hostpath_provisioner.version, namespaceName);
local bundle_schedule = helper.load('ssp-%s/operator.yaml' % params.operators.schedule_scale.version, namespaceName);
local bundle_quota = helper.load('mtq-%s/operator.yaml' % params.operators.tenant_quota.version, namespaceName);

local instance_olm = helper.instance('olm', namespaceName);

local instance_kubevirt = helper.instance('kubevirt', namespaceName);
local instance_importer = helper.instance('data_importer', namespaceName);
local instance_network = helper.instance('network_addons', namespaceName);
local instance_hostpath = helper.instance('hostpath_provisioner', namespaceName);
local instance_schedule = helper.instance('schedule_scale', namespaceName);
local instance_quota = helper.instance('tenant_quota', namespaceName);

local bundles_and_instances = {
  [if helper.isEnabled('kubevirt') then '10_bundle_kubevirt']: bundle_kubevirt,
  [if helper.isEnabled('data_importer') then '10_bundle_importer']: bundle_importer,
  [if helper.isEnabled('network_addons') then '10_bundle_network']: bundle_network,
  [if helper.isEnabled('hostpath_provisioner') then '10_bundle_hostpath']: bundle_hostpath,
  [if helper.isEnabled('schedule_scale') then '10_bundle_schedule']: bundle_schedule,
  [if helper.isEnabled('tenant_quota') then '10_bundle_quota']: bundle_quota,
  [if helper.isEnabled('kubevirt') then '20_instance_kubevirt']: instance_kubevirt,
  [if helper.isEnabled('data_importer') then '20_instance_importer']: instance_importer,
  [if helper.isEnabled('network_addons') then '20_instance_network']: instance_network,
  [if helper.isEnabled('hostpath_provisioner') then '20_instance_hostpath']: instance_hostpath,
  [if helper.isEnabled('schedule_scale') then '20_instance_schedule']: instance_schedule,
  [if helper.isEnabled('tenant_quota') then '20_instance_quota']: instance_quota,
};

// Types and Preferences
local vm_types = {
  ['30_type_' + name]: kube._Object('instancetype.kubevirt.io/v1beta1', 'VirtualMachineClusterInstancetype', name) {
    metadata+: {
      labels+: {
        'app.kubernetes.io/managed-by': 'commodore',
        'app.kubernetes.io/name': name,
      },
    },
    spec+: params.vm.types[name],
  }
  for name in std.objectFields(params.vm.types)
};

// Preferences
local vm_preferences = {
  ['40_preference_' + name]: kube._Object('instancetype.kubevirt.io/v1beta1', 'VirtualMachineClusterPreference', name) {
    metadata+: {
      labels+: {
        'app.kubernetes.io/managed-by': 'commodore',
        'app.kubernetes.io/name': name,
      },
    },
    spec+: params.vm.preferences[name],
  }
  for name in std.objectFields(params.vm.preferences)
};

// Define outputs below
{
  '00_namespace': namespace,
}
+ vm_types
+ vm_preferences
+ if helper.deployOlm then {
  '10_operator_group': operator_group,
  '10_subscription': subscription,
  '20_instance': instance_olm,
} else bundles_and_instances
