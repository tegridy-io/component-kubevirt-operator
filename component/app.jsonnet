local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator;
local argocd = import 'lib/argocd.libjsonnet';
local helper = import 'helper.libsonnet';

local app = argocd.App('kubevirt-operator', params.namespace.name);

{
  'kubevirt-operator': app {
    spec+: {
      syncPolicy+: {
        syncOptions+: [
          'ServerSideApply=true',
        ],
      },
    },
  },
}
