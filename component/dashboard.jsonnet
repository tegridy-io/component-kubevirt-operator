// dashboard template for kubevirt-operator
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local olm = import 'lib/olm.libsonnet';

local helper = import 'helper.libsonnet';

// The hiera parameters for the component
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator;
local isOpenshift = std.startsWith(inv.parameters.facts.distribution, 'openshift');

// Namespace
local namespace = kube.Namespace(params.dashboard.namespace.name) {
  metadata+: {
    annotations+: params.dashboard.namespace.annotations,
    labels+: {
      // Configure the namespaces so that the OCP4 cluster-monitoring
      // Prometheus can find the servicemonitors and rules.
      [if isOpenshift then 'openshift.io/cluster-monitoring']: 'true',
    } + com.makeMergeable(params.dashboard.namespace.labels),
  },
};

// Bundle
local manifests = helper.load('dashboard-main/bundled.yaml', params.dashboard.namespace.name);

local patchImage(resource) = if resource.kind == 'Deployment' then
  resource {
    spec+: {
      template+: {
        spec+: {
          containers: std.map(
            function(it) it {
              [if it.name == 'kubevirtmgr' then 'image']: '%(registry)s/%(repository)s:%(tag)s' % params.images.dashboard,
            },
            resource.spec.template.spec.containers
          ),
        },
      },
    },
  } else resource;

local bundle = std.map(
  patchImage,
  manifests
);

// Define outputs below
{
  [if helper.isEnabled('dashboard') then '00_namespace_dashboard']: namespace,
  [if helper.isEnabled('dashboard') then '10_bundle_dashboard']: bundle,
}
