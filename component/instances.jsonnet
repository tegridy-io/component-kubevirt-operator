// main template for kubevirt-operator
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator;

local prefixedName(name) = params.instancePrefix + '-' + name;

// Define outputs below
{
  ['20_kubevirt_' + name]: [
    kube.Namespace(prefixedName(name)) {
      local spec = std.get(params.instances[name], 'namespace', { labels: {}, annotations: {} }),
      metadata+: {
        annotations: spec.annotations,
        labels+: spec.labels {
          'app.kubernetes.io/managed-by': 'commodore',
          'app.kubernetes.io/name': prefixedName(name),
        },
      },
    },
    kube._Object('kubevirt.io/v1', 'KubeVirt', 'instance') {
      local spec = params.instances[name],
      metadata+: {
        labels+: {
          'app.kubernetes.io/managed-by': 'commodore',
          'app.kubernetes.io/name': 'instance',
          'app.kubernetes.io/instance': name,
        },
        namespace: prefixedName(name),
      },
      spec+: {
        [k]: spec[k]
        for k in std.objectFields(spec)
        if k != 'namespace'
      },
    },
  ]
  for name in std.objectFields(params.instances)
}
