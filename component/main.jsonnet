// main template for kubevirt-operator
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator;
local isOpenshift = std.startsWith(inv.parameters.facts.distribution, 'openshift');

// Namespace
local namespace = kube.Namespace(params.namespace) {
  metadata+: {
    labels+: {
      'kubevirt.io': '',
      'app.kubernetes.io/name': params.namespace,
      'pod-security.kubernetes.io/enforce': 'privileged',
      // Configure the namespaces so that the OCP4 cluster-monitoring
      // Prometheus can find the servicemonitors and rules.
      [if isOpenshift then 'openshift.io/cluster-monitoring']: 'true',
    },
  },
};

// Manifests
local manifests = std.parseJson(kap.yaml_load_stream('kubevirt-operator/manifests/%s/kubevirt-operator.yaml' % params.manifestsVersion));

local serviceAccount = [
  it { metadata+: { namespace: params.namespace } }
  for it in std.filter(function(it) it.kind == 'ServiceAccount', manifests)
];


local clusterRole = std.filter(function(it) it.kind == 'ClusterRole', manifests);

local role = [
  it { metadata+: { namespace: params.namespace } }
  for it in std.filter(function(it) it.kind == 'Role', manifests)
];

local clusterRoleBinding = kube.ClusterRoleBinding('kubevirt-operator') {
  metadata+: {
    labels: {
      'kubevirt.io': '',
    },
  },
  roleRef_: clusterRole[1],
  subjects_: serviceAccount,
};

local roleBinding = kube.RoleBinding('kubevirt-operator') {
  metadata+: {
    labels: {
      'kubevirt.io': '',
    },
    namespace: params.namespace,
  },
  roleRef_: role[0],
  subjects_: serviceAccount,
};

local deployment = [
  it {
    metadata+: {
      namespace: params.namespace,
    },
    spec+: {
      replicas: params.operator.replicas,
    },
  }
  for it in std.filter(function(it) it.kind == 'Deployment', manifests)
];


// Define outputs below
{
  '00_namespace': namespace,
  '00_crds': std.filter(function(it) it.kind == 'CustomResourceDefinition', manifests),
  '00_priorityclass': std.filter(function(it) it.kind == 'PriorityClass', manifests),
  '10_rbac': serviceAccount + clusterRole + role + [ clusterRoleBinding, roleBinding ],
  '10_deployment': deployment,
}
