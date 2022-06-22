// main template for openshift4-keepalived
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local operatorlib = import 'lib/openshift4-operators.libsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.openshift4_keepalived;
local image = 'registry.redhat.io/openshift4/ose-keepalived-ipfailover:v' + params.openshift_version;

local namespace =
  kube.Namespace(params.namespace)
  {
    metadata+: {
      annotations+: {
        // Allow Pods to be scheduled on any Node
        'openshift.io/node-selector': '',
      },
    },
  };

local keepalived_groups = std.filter(
  function(it) it != null,
  [
    local formated_name = kube.hyphenate(keepalived_object);
    local keepalived_group = params.keepalived_groups[keepalived_object];
    if keepalived_group != null then
      kube._Object('redhatcop.redhat.io/v1alpha1', 'KeepalivedGroup', formated_name) {
        metadata+: {
          namespace: params.namespace,
        },
        spec+: {
          image: image,
        },
      } + com.makeMergeable(keepalived_group)
    for keepalived_object in std.objectFields(params.keepalived_groups)
  ]
);

{
  '00_namespace': namespace,
  '00_operator_group': operatorlib.OperatorGroup('cluster-keepalived') {
    metadata+: {
      namespace: params.namespace,
    },
  },
  '10_subscription': operatorlib.namespacedSubscription(
    params.namespace,
    'keepalived-operator',
    params.channel,
    'community-operators'
  ),
  [if std.length(keepalived_groups) > 0 then '20_keepalived_groups']: keepalived_groups,
}
