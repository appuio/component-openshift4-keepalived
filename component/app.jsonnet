local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.openshift4_keepalived;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('openshift4-keepalived', params.namespace);

{
  'openshift4-keepalived': app,
}
