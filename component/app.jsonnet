local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local operators = inv.parameters.kubevirt_operator.operators;
local argocd = import 'lib/argocd.libjsonnet';

local helper = import 'helper.libsonnet';

local app = argocd.App('kubevirt-operator', operators.kubevirt.namespace.name);

{
  [if helper.hasKubevirt then 'kubevirt-operator']: app {
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
  [if helper.hasImporter then 'kubevirt-cdi']: app {
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
  [if helper.hasHyperconverged then 'kubevirt-operator']: app {
    spec+: {
      source: {
        path: 'manifests/kubevirt-operator',
      },
      syncPolicy+: {
        syncOptions+: [
          'ServerSideApply=true',
        ],
      },
    },
  },
}
