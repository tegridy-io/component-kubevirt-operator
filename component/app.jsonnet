local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('kubevirt-operator', params.kubevirt.namespace.name);
local hasKubevirt = params.operators.kubevirt.enabled;
local hasImporter = params.operators.importer.enabled;

{
  [if hasKubevirt then 'kubevirt-operator']: app {
    spec+: {
      source: {
        path: 'manifests/kubevirt-operator/kubevirt',
      },
      syncPolicy+: {
        syncOptions+: [
          'ServerSideApply=true',
        ],
      },
    },
  },
  [if hasImporter then 'kubevirt-cdi']: app {
    spec+: {
      source: {
        path: 'manifests/kubevirt-operator/importer',
      },
      syncPolicy+: {
        syncOptions+: [
          'ServerSideApply=true',
        ],
      },
    },
  },
}
