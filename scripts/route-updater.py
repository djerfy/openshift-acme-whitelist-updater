#!/usr/bin/python

import os, sys, yaml
from datetime import datetime
from kubernetes import config, client
from openshift.dynamic import DynamicClient


def WhitelistRouteUpdater():
    """
    Set ACME routes with `haproxy.router.openshift.io/ip_whitelist: 0.0.0.0` annotation
    """

    config.load_incluster_config()
    file_namespace = open('/run/secrets/kubernetes.io/serviceaccount/namespace', 'r')
    if file_namespace == 'r':
        namespace = file_namespace.read()
        print("Running in namespace: {}".format(namespace))

    kubernetes_config = client.Configuration()
    kubernetes_client = client.api_client.ApiClient(configuration=k8s_config)
    openshift_client  = DynamicClient(kubernetes_client)

    routes = openshift_client.resources.get(api_version='v1', kind='Route')
    if routes:
        print("Starting stream routes event")
    else:
        print("Error: failed stream routes event")
        exit(1)

    for route in routes.watch():
        dt_now = datetime.now()
        dt_str = dt_now.strftime("%Y-%m%-%d %H:%M:%S")

        eventType       = route['type']
        routeName       = route['object'].metadata.name
        routeNamespace  = route['object'].metadata.namespace
        routePath       = route['object'].spec.path
        routeWhitelist  = route['object'].metadata.annotations['haproxy.router.openshift.io/ip_whitelist']

        print("{}: Detected event '{}' from route '{}/{}'".format(
            dt_str,
            eventType,
            routeNamespace,
            routeName))

        if eventType == 'DELETED':
            continue

        if routeName.startswith('exposer-') and routePath.startswith('/.well-known/acme-challenge'):
            routePatch = {
                'apiVersion': 'v1',
                'kind': 'Route',
                'metadata': {
                    'name': routeName,
                    'annotations': {
                        'haproxy.router.openshift.io/ip_whitelist': routeIps
                    }
                }
            }
    
            if routes.patch(body=routePatch, namespace=routeNamespace):
                routePatched = 'Updated'
            else:
                routePatched = 'Failed'
    
            print("{}: {} ip_whitelist annotation into namespace '{}' and route '{}'".format(
                dt_str,
                routePatched,
                routeNamespace,
                routeName))
            print("Patch: {}".format(
                routePatch))    
            print("")


if __name__ == '__main__':
    WhitelistRouteUpdater()
