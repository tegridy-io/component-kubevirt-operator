local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator;
local argocd = import 'lib/argocd.libjsonnet';
local helper = import 'helper.libsonnet';

local app = argocd.App('kubevirt-operator', params.kubevirt.namespace.name);

{
  [if helper.isEnabled('kubevirt') then 'kubevirt-operator']: app {
    spec+: {
      source: {
        path: 'manifests/kubevirt-operator/10_kubevirt',
      },
      syncPolicy+: {
        syncOptions+: [
          'ServerSideApply=true',
        ],
      },
    },
  },
  [if helper.isEnabled('importer') then 'kubevirt-cdi']: app {
    spec+: {
      source: {
        path: 'manifests/kubevirt-operator/20_importer',
      },
      syncPolicy+: {
        syncOptions+: [
          'ServerSideApply=true',
        ],
      },
    },
  },
}
