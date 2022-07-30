# kubegates

kubegates facilitates the use of multiple Kubernetes contexts, independenly of each other, safely, in a selective isolation.

The scope of this concept was to make it possible to work with multiple Kubernetes clusters, withouth having to switch context continuously, and to manage different versions of the kubectl client to match the version in the server.

## Set up

Start by creating a root directory named `kubegates` and under it, two other directories: `lib` and `bin`</br>
Copy the file `activate` into `lib` and download the versions you need of the binary kubectl into `bin`. Rename kubectl with a suffix that represents the specific release version. You may also make use of other binaries like helm</br>
Look in this repo, under the directoy `utils` for some scripts that will help you to do download versions of kubectl and helm. The scripts might need some modifications to accomodate your directory structure.

After that, build your hierachy tree with organization identifiers (clients, companies, teams, business units). Under each organizational group create a directory for each kubernetes cluster. This kubernetes cluster name will be verified when activating it, therefore, it must match the given context cluster name. Use symbolic links to target the activate file in `lib`, the binaries targets.
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

To safetly start using multiple Kuberntes contexts, without switching, source the activate file for any cluster that you want.

Example

```
source kubegates/clientname/qa-eks-1/activate
```

At any time you may get the original prompt and terminal back by deactivating

```
deactivate
```

## Many possibilities

Once you have kubegates setup you can have many options available to access your clusters.
One posibility is to create aliases

```
alias kqa1="source kubegates/clientname/qa-eks-1/activate"
alias kstg0="source kubegates/clientname/stg-eks-0/activate"
```

Another posibility is to use a multiplexer terminal that allows you to automatically source the cluster name and create a pane for each cluster.

Look into the `script konnect.sh` for an example using tmux

![Alt text](assets/kubegates_tmux.png?raw=true "kubegates tmux")
