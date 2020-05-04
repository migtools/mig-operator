
## Collecting CAM debug info with must-gather

CAM [*must-gather*](https://github.com/konveyor/must-gather) is a tool for gathering useful debug info related to a CAM installation. 

If you're having trouble migrating workloads with CAM and want to share info about your installation, it may be useful to include *must-gather* artifacts in the associated GitHub issue or Bugzilla.

---

### Running CAM must-gather

1. Ensure you are connected to an OpenShift cluster running the CAM controller and UI. You must be using a recent OpenShift 4.x `oc` client version for the `oc adm must-gather` command to be available.

2. Gather a set of debug logs and artifacts relating to your current CAM installation
```
oc adm must-gather --image=quay.io/konveyor/must-gather:latest
```

3. Wait for completion of must-gather container. This could take several minutes.

4. Examine the resulting must-gather directory, e.g. `{pwd}/must-gather.local.{uid}`

5. Remove any sensitive information in the local must-gather output (e.g. cloud authentication keys) before adding must-gather data to issue report.

---

### Collected logs and artifacts

You learn more about data that is collected by reading the [collection scripts](https://github.com/konveyor/must-gather/tree/master/collection-scripts), or by looking at the generated output from running CAM must-gather.
