# Volt Active Data : Rating and charging on kubernetes.

### Powerful and simplistic solution.

- This sandbox aims to demonstrate how **Volt Active Data** can help in scenarios such as telcommunications where users are working with *shared and finite resources* while meeting SLAs, such as SMS messages or bandwidth. 
- With the recent move in industry towards containerization and cloud architecture, we want to showcase Volt readiness and easy to use approach for integrating in a cloud native ecosystem with leading tools like **Docker** and **Kubernetes**.
- The demo is a drastically simplified representation of what's known as a 'charging' system. Every prepaid cell phone uses one of these, it decides what the user can do, how long they can do it for, and tells downstream systems what was used when the activity finishes. Following activities happen in this deployment:

1. "Provision" a user : This happens once, and is the part where they enter the number on your sim card into the computer at the store so the phone systems knows that that sim card is now 1-510-555-1212 or whatever your number is.

2. "Add Credit" : This is when a third party system tells the phone company's computer that you have just gone to a recharging center and added US$20 in credit.

3. "Report Usage and Reserve More" : In real life this is several steps, but to keep things simple we use one. In this the phone system tells VoltDB how much of a resource you've used ("Usage"), and how much they think you'll need over the next 30 seconds or so ("Reserve"). Normal practice is to hand over a larger chunk than we think you'll need, as if you run out we may have to freeze your ability to call or internet activity, depending on your usage, until we get more. For a given user this is happening about once every 30 seconds, for each activity.

4. A downstream system configured in this example is kafka, which is running in the same kubernetes cluster as volt. the export stream User_financial_events, is populated when any user in the system add or spend money. this information can be useful for realtime personalisation decisions and customisation of service to end users.

5. the sandbox also consists of volt active data monitoring setup consisting of prometheus and grafana running on the same kubernetes cluster to capture and visualise statistics of volt and underlying containers and nodes performance. setting up alerts here can help mitigate risks before they cause disruption in service impacting business. With k8s volt takes advantage of features like auto-healing and helm deployments to enable engineers to use and maintain volt easily and efficiently.



### Prerequisites

- install gcloud and kubeclt on the machine from where the scripts will be executed. Provide the necessary authentication for your google cloud account to use gcloud successfully.

## How to run

Checkout this repo, edit the following variables in powercluster.sh as per your prefernce,

| Variable name | Description | Example Value |
| ------------- | ----------- | ------------- |
|CLUSTER_NAME  | Name of the GKE cluster |	"voltactivedata-lab" |
|MACHINE_TYPE	| Type of google cloud compute machine	|"c2-standard-8" |
|NUM_NODES|	Number of nodes in the cluster	| "3" |
|MONITORING_NS|	Namespace name for monitoring deployments	|"monitoring" |
|VOLT_NS |	Namespace name for VOLT deployments |	"voltdb" |
|KAFKA_NS |	Namespace name for KAFKA deployments |	"kafka"   |
|DOCKER_ID |	Docker details for test client image |	use default provided in script |
|DOCKER_API	| Docker details for test client image	use default |provided in script |
|DOCKER_EMAIL |	Docker details for test client image |	use default provided in script |
|MONITORING_VERSION |	Version of helm charts for monitoring	|"10.1.0" |
|VOLT_DEPLPOYMENTNAME |	name of helm deployment for volt	|"mydb" |
|PROPERTY_FILE |	custom values.yaml file with configurations	|myproperties.yam |
|LICENSE_FILE	|Absolute path of license.xml |	"/Users/Documents/license.xml"
|COMMANDLOG_ENABLED	|Is command log enabled (true/false)| false |
|SNAPSHOT_ENABLED |	Is snapshot enabled (true/false) |	false | 
|ZK_SVC	|zookeeper service name for kafka	|"zookeeper.kafka.svc.cluster.local" |


