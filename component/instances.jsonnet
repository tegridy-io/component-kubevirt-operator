// main template for kubevirt-operator
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator;

// Define outputs below
{
  ['30_instancetype_' + name]: kube._Object('instancetype.kubevirt.io/v1beta1', 'VirtualMachineClusterInstancetype', name) {
    metadata+: {
      labels+: {
        'app.kubernetes.io/managed-by': 'commodore',
        'app.kubernetes.io/name': name,
      },
    },
    spec+: params.instanceTypes[name],
  }
  for name in std.objectFields(params.instanceTypes)
}
