// Helper function
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator;

// OLM
local deployOlm = params.olm.enabled;

// Config
local config(component) = if deployOlm then
  com.makeMergeable(params.config.schedule_scale)
  + com.makeMergeable(params.config.tenant_quota)
  + com.makeMergeable(params.config.hostpath_provisioner)
  + com.makeMergeable(params.config.network_addons)
  + com.makeMergeable(params.config.data_importer)
  + com.makeMergeable(params.config.kubevirt)
else
  std.get(params.config, component, {});

// Component
local isEnabled(component) = std.get(params.operators, component, { enabled: false }).enabled;
local hasConfig(component) = std.length(config(component)) > 0;

// Loading and patching manifests
local clusterScoped = [
  'ClusterRole',
  'ClusterRoleBinding',
  'CustomResourceDefinition',
  'Namespace',
  'PriorityClass',
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
};
local instance(component, namespace) = _instanceObj[component] {
  metadata+: {
    labels: {
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': 'instance',
      'app.kubernetes.io/instance': component,
    },
    name: 'instance',
    namespace: namespace,
  },
  spec: config(component),
};

// Define outputs below
{
  load: patchManifests,
  instance: instance,
  isEnabled: isEnabled,
  hasConfig: hasConfig,
  deployOlm: deployOlm,
}
