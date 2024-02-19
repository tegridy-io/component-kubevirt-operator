// main template for kubevirt-operator
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator;

// Define outputs below
{
  '20_kubevirt': kube._Object('kubevirt.io/v1', 'KubeVirt', 'instance') {
    metadata+: {
      labels+: {
        'app.kubernetes.io/managed-by': 'commodore',
        'app.kubernetes.io/name': 'instance',
        'app.kubernetes.io/instance': 'instance',
      },
      namespace: params.namespace,
    },
    spec+: params.instance,
  },
}
