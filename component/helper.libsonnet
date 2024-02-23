local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator;

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
  data_importer: {
    apiVersion: 'cdi.kubevirt.io/v1beta1',
    kind: 'CDI',
  },
  hostpath_provisioner: {
    apiVersion: 'hostpathprovisioner.kubevirt.io/v1beta1',
    kind: 'HostPathProvisioner',
  },
};
local instance(component, namespace, config={}) = _instanceObj[component] {
  metadata+: {
    labels: {
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': 'instance',
      'app.kubernetes.io/instance': component,
    },
    namespace: namespace,
  },
  spec: if std.length(config) > 0 then config else std.get(params.config, component, {}),
};

// Component
local componentEnabled(component) =
  if component == 'hyperconverged' then
    params.operators.hyperconverged.enabled
  else
    std.get(params.operators, component, { enabled: false }).enabled
    && !params.operators.hyperconverged.enabled;

{
  load: patchManifests,
  instance: instance,
  isEnabled: componentEnabled,
}
