# kubegates

kubegates facilitates the use of multiple Kubernetes contexts, at the same time, safely in selective isolation.

The scope of this concept was to make it possible to work with multiple Kubernetes clusters, withouth having to switch context, continuously and manage different versions of kubectl to match the version in the server.

## Set up

Start by creating a root directory named `kubegates` and under it, two other directories: `lib` and `bin`</br>
Copy the file `activate` into `lib` and download the versions you need of the binary kubectl into `bin`. Rename kubectl with a suffix that represents the specific release version. You may also make use of other binaries like helm
Look in this repo under the directoy utils for scripts that will help you to do download versions of kubectl and helm

After that build your hierachy tree of organizations (clients, teams, business units). Under each organizational group create a directory for each kubernetes cluster. This kubernetes cluster name will be checked when activating. Use symbolic links to target the activate file in lib, the binaries targets.
Still, under the cluster directory create a kubernetes config file that contains only the context you are trying to isolate.

The following is an example of the structure that would result performing the instructions above.

```
kubegates/
├── bin
│   ├── helm-v3.9.1
│   ├── kubectl-v1.21.12
│   ├── kubectl-v1.21.5
│   ├── kubectl-v1.22.10
│   └── kubectl-v1.24.3
├── laboratory
│   └── fj
│       ├── activate -> ../../lib/activate
│       ├── config
│       ├── helm -> ../../bin/helm-v3.9.1
│       └── kubectl -> ../../bin/kubectl-v1.22.10
├── clientname
│   ├── mgmt-eks-0
│   │   ├── activate -> ../../lib/activate
│   │   ├── color
│   │   ├── config
│   │   └── kubectl -> ../../bin/kubectl-v1.21.5
│   ├── prod-eks-0
│   │   ├── activate -> ../../lib/activate
│   │   ├── color
│   │   ├── config
│   │   └── kubectl -> ../../bin/kubectl-v1.21.5
│   ├── qa-eks-1
│   │   ├── activate -> ../../lib/activate
│   │   └── config
│   ├── qa-eks-2
│   │   ├── activate -> ../../lib/activate
│   │   ├── config
│   │   ├── kubectl -> ../../bin/kubectl-v1.21.5
│   └── stg-eks-0
│       ├── activate -> ../../lib/activate
│       ├── config
│       └── kubectl -> ../../bin/kubectl-v1.21.12
└── lib
    └── activate
```

## Activate

To safetly start using multiple kuberntes contexts, without switching, source the activate file for any cluster that you want.

Example

```
source kubegates/clientname/qa-eks-1/activate
```

At any time you may get the original prompt and terminal back by deactivating

```
deactivate
```
