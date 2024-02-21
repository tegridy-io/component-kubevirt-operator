// main template for kubevirt-operator
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local helper = import 'helper.libsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local namespace = inv.parameters.kubevirt_operator.namespace;
local operator = inv.parameters.kubevirt_operator.operators.importer;
local config = inv.parameters.kubevirt_operator.config.importer;

// CDI
local instance = kube._Object('cdi.kubevirt.io/v1beta1', 'CDI', 'instance') {
  metadata+: {
    labels: {
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': 'instance',
      'app.kubernetes.io/instance': 'instance',
    },
    namespace: namespace.name,
  },
  spec: config,
};

// Define outputs below
{
  bundle: helper.load('cdi-%s/cdi-operator.yaml' % operator.version, namespace.name),
  instance: instance,
}
