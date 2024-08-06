package main

import (
	"flag"
	"fmt"
	"log"
	"path/filepath"
  "sort"

  "k8s.io/client-go/discovery"
  "k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/homedir"
)

// Resource holds information about a Kubernetes resource
type Resource struct {
  Name string
  Group string
  Namespaced bool
}

// GetK8sConfig returns the Kubernetes client configuration
/*
func GetK8sConfig() (*rest.Config, error) {
    var kubeconfig string
    if home := homedir.HomeDir(); home != "" {
        kubeconfig = filepath.Join(home, ".kube", "config")
    } else {
        return nil, fmt.Errorf("could not find home directory")
    }

    config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
    if err != nil {
        return nil, err
    }
    return config, nil
}
*/

func main() {
	var kubeconfig *string
	if home := homedir.HomeDir(); home != "" {
		kubeconfig = flag.String("kubeconfig", filepath.Join(home, ".kube", "config"), "(optional) absolute path to the kubeconfig file")
	} else {
		kubeconfig = flag.String("kubeconfig", "", "absolute path to the kubeconfig file")
	}
	flag.Parse()

	// use the current context in kubeconfig
	config, err := clientcmd.BuildConfigFromFlags("", *kubeconfig)
	if err != nil {
		log.Fatalf("Error getting Kubernetes config: %v", err)
	}

	// create the clientset
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
    log.Fatalf("Error creating Kubernetes client: %v", err)
	}

  // Create a Discovery client
  discoveryClient := discovery.NewDiscoveryClient(clientset.RESTClient())

  // Get the API resources
  apiResourceList, err := discoveryClient.ServerPreferredResources()
  if err != nil {
      log.Fatalf("Error getting API resources: %v", err)
  }

  // fmt.Println(apiResourceList)
  // panic("The end")

  // Collect the resources in a slice
  var resources []Resource
  for _, apiResourceGroup := range apiResourceList {
      if apiResourceGroup == nil {
          continue
      }
      for _, apiResource := range apiResourceGroup.APIResources {
          resources = append(resources, Resource{
              Name: apiResource.Name,
              Group: apiResource.Group,
              Namespaced: apiResource.Namespaced,
          })
      }
  }

  // Sort the resources by name
  sort.Slice(resources, func(i, j int) bool {
      return resources[i].Name < resources[j].Name
  })

  // Print the sorted resources
  for _, resource := range resources {
      fmt.Printf("Name: %s, Group: %s, Namespaced: %v\n", resource.Name, resource.Group, resource.Namespaced)
  }
}
