local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator;
local argocd = import 'lib/argocd.libjsonnet';
local helper = import 'helper.libsonnet';

local namespaceName = if helper.deployOlm then 'kubevirt-hyperconverged'
else params.namespace.name;

local app = argocd.App('kubevirt-operator', namespaceName);

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
