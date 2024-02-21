// main template for kubevirt-operator
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local olm = import 'lib/olm.libsonnet';

local helper = import 'helper.libsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local operator = inv.parameters.kubevirt_operator.operators.hyperconverged;


// Define outputs below
if operator.enabled then
  {
    '50_operator_group': olm.OperatorGroup('kubevirt-operators') {
      metadata+: {
        namespace: params.namespace.name,
      },
      spec: {
        targetNamespaces: [
          params.namespace.name,
        ],
      },
    },
    '50_subscriptions': [
      olm.namespacedSubscription(
        params.namespace,
        'kubevirt',
        params.channel,
        'redhat-operators'
      ) {
        spec+: {
          config+: {
            resources: params.operatorResources.clusterLogging,
          },
        },
      },
    ],
  } + {
    '10_operator_source': kube._Object('operators.coreos.com/v1', 'OperatorSource', 'kubevirt') {

    },
  }
