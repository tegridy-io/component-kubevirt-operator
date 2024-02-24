// Helper function
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator;

// Component
local deployOlm = params.olm.enabled;
local isEnabled(component) = if component == 'dashboard' then params.dashboard.enabled
else std.get(params.operators, component, { enabled: false }).enabled;

// Loading and patching manifests
local clusterScoped = [
  'ClusterRole',
  'ClusterRoleBinding',
  'CustomResourceDefinition',
  'MutatingWebhookConfiguration',
  'Namespace',
  'PriorityClass',
  'ValidatingWebhookConfiguration',
];
local bindings = [
  'ClusterRoleBinding',
  'RoleBinding',
];

local patch(resource, namespace) = resource {
  metadata+: {
    labels+: {
      [if resource.kind != 'CustomResourceDefinition' then 'app.kubernetes.io/managed-by']: 'commodore',
    },
    [if !std.member(clusterScoped, resource.kind) then 'namespace']: namespace,
  },
  [if std.member(bindings, resource.kind) then 'subjects']: std.map(
    function(it) it { namespace: namespace },
    resource.subjects
  ),
};

local manifests(path) = std.filter(
  function(it) it.kind != 'Namespace',
  std.parseJson(kap.yaml_load_stream(path))
);

local patchManifests(path, namespace) = std.map(
  function(it) patch(it, namespace),
  manifests('kubevirt-operator/manifests/' + path)
);

// Config
local config(component) = if deployOlm then {
  [k]: params.config[k]
  for k in std.filter(
    function(it) !std.member(
      [
        'kubevirt',
        'data_importer',
        'network_addons',
        'hostpath_provisioner',
        'schedule_scale',
        'tenant_quota',
      ],
      it
    ),
    std.objectFields(params.config)
  )
}
else
  std.get(params.config, component, {});

// Instances
local _instanceObj = {
  olm: {
    apiVersion: 'hco.kubevirt.io/v1beta1',
    kind: 'HyperConverged',
  },
  kubevirt: {
    apiVersion: 'kubevirt.io/v1',
    kind: 'KubeVirt',
  },
  data_importer: {
    apiVersion: 'cdi.kubevirt.io/v1beta1',
    kind: 'CDI',
  },
  network_addons: {
    apiVersion: 'networkaddonsoperator.network.kubevirt.io/v1',
    kind: 'NetworkAddonsConfig',
  },
  hostpath_provisioner: {
    apiVersion: 'hostpathprovisioner.kubevirt.io/v1beta1',
    kind: 'HostPathProvisioner',
  },
  schedule_scale: {
    apiVersion: 'ssp.kubevirt.io/v1beta2',
    kind: 'SSP',
  },
  tenant_quota: {
    apiVersion: 'mtq.kubevirt.io/v1alpha1',
    kind: 'MTQ',
  },
};
local instance(component, namespace) = _instanceObj[component] {
  metadata+: {
    labels: {
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': 'instance',
      'app.kubernetes.io/instance': component,
    },
    name: if component == 'olm' then 'kubevirt-hyperconverged' else 'instance',
    namespace: namespace,
  },
  spec: config(component),
};

// Define outputs below
{
  load: patchManifests,
  instance: instance,
  isEnabled: isEnabled,
  deployOlm: deployOlm,
}
