// main template for kubevirt-operator
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local cluster = inv.parameters.kubevirt_operator.cluster;

// Define outputs below
{
  ['80_type_' + name]: kube._Object('instancetype.kubevirt.io/v1beta1', 'VirtualMachineClusterInstancetype', name) {
    metadata+: {
      labels+: {
        'app.kubernetes.io/managed-by': 'commodore',
        'app.kubernetes.io/name': name,
      },
    },
    spec+: cluster.types[name],
  }
  for name in std.objectFields(cluster.types)
} + {
  ['80_preference_' + name]: kube._Object('instancetype.kubevirt.io/v1beta1', 'VirtualMachineClusterPreference', name) {
    metadata+: {
      labels+: {
        'app.kubernetes.io/managed-by': 'commodore',
        'app.kubernetes.io/name': name,
      },
    },
    spec+: cluster.preferences[name],
  }
  for name in std.objectFields(cluster.preferences)
}
