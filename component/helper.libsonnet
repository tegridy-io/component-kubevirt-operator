local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local operators = inv.parameters.kubevirt_operator.operators;

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

{
  load: patchManifests,
  hasKubevirt: if operators.kubevirt.enabled && !operators.hyperconverged.enabled then true else false,
  hasImporter: if operators.importer.enabled && !operators.hyperconverged.enabled then true else false,
  hasHyperconverged: operators.hyperconverged.enabled,
  isOpenshift: std.startsWith(inv.parameters.facts.distribution, 'openshift'),
}
