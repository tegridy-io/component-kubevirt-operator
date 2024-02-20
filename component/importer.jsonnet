// main template for kubevirt-operator
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator.importer;
local isOpenshift = std.startsWith(inv.parameters.facts.distribution, 'openshift');

// Namespace
local namespace = kube.Namespace(params.namespace.name) {
  metadata+: {
    annotations+: params.namespace.annotations,
    labels+: {
      // Configure the namespaces so that the OCP4 cluster-monitoring
      // Prometheus can find the servicemonitors and rules.
      [if isOpenshift then 'openshift.io/cluster-monitoring']: 'true',
    } + com.makeMergeable(params.namespace.labels),
  },
};

// Manifests
local manifests = std.parseJson(kap.yaml_load_stream('kubevirt-operator/manifests/cdi-%s/cdi-operator.yaml' % params.version));

local serviceAccount = [
  it { metadata+: { namespace: params.namespace.name } }
  for it in std.filter(function(it) it.kind == 'ServiceAccount', manifests)
];


local clusterRole = std.filter(function(it) it.kind == 'ClusterRole', manifests);

local role = [
  it { metadata+: { namespace: params.namespace.name } }
  for it in std.filter(function(it) it.kind == 'Role', manifests)
];

local clusterRoleBinding = kube.ClusterRoleBinding('kubevirt-operator') {
  metadata+: {
    labels: {
      'operator.cdi.kubevirt.io': '',
    },
  },
  roleRef_: clusterRole[0],
  subjects_: serviceAccount,
};

local roleBinding = kube.RoleBinding('kubevirt-operator') {
  metadata+: {
    labels: {
      'cdi.kubevirt.io': '',
    },
    namespace: params.namespace.name,
  },
  roleRef_: role[0],
  subjects_: serviceAccount,
};

local deployment = [
  it {
    metadata+: {
      namespace: params.namespace.name,
    },
    spec+: {
      replicas: params.replicas,
    },
  }
  for it in std.filter(function(it) it.kind == 'Deployment', manifests)
];

local instance = kube._Object('cdi.kubevirt.io/v1beta1', 'CDI', 'instance') {
  metadata+: {
    labels: {
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': 'instance',
      'app.kubernetes.io/instance': 'instance',
    },
    namespace: params.namespace.name,
  },
  spec: params.spec,
};


// Define outputs below
{
  '20_cdi_namespace': namespace,
  '20_cdi_crds': std.filter(function(it) it.kind == 'CustomResourceDefinition', manifests),
  '21_cdi_rbac': serviceAccount + clusterRole + role + [ clusterRoleBinding, roleBinding ],
  '22_cdi_deployment': deployment,
  '23_cdi_instance': instance,
}
