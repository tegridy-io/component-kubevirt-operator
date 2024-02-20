local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.kubevirt_operator;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('kubevirt-operator', params.kubevirt.namespace.name);

{
  'kubevirt-operator': app,
}
