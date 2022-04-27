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


### Starting the Sandbox

Checkout this repo,
Edit the following variables in `powercluster.sh` as per your prefernce,

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

This file will handle the following operations,
(Picture of flow diagram1)


After making changes to the variable, save and run the file:

`sh powerCluster.sh`

The output of the script will be printed in the terminal, on successful execution the following message will be printed directing to the IP and Port to access Volt and Grafana UI.

```

Batch command succeeded.
IP for UI access
34.105.220.28
VolTB Port for UI access
8080:31080/TCP
grafana Port for UI access
80:30099/TCP

```

### The simulated System

Our demo phone company has 4 products. As in real life, a user can use more than one at once:

| Product | Unit Cost |
| --- | --- |
| The phone company&#39;s  web site. Customers can always access the phone company&#39;s web site, even if they are out of money. | 0 |
| SMS messages, per message. | 1c |
| Domestic Internet Access per GB | 20c |
| Roaming Internet Access per GB | $3.42 |
| Domestic calls per minute | 3c |


This means that when serving requests we need to turn the incoming request for &#39;access per GB&#39; into real money and compare it to the user&#39;s balance when deciding how much access to grant .

**We have to factor in reserved balances when making decisions**

- We shouldn&#39;t let you spend money you haven&#39;t got, so your usable balance has to take into account what you&#39;ve reserved. Note that any credit you&#39;ve reserved affects your balance immediately, so your balance can sometimes spike up slightly if you reserve 800 units and then come back reporting usage of 200.


- Like any real world production code we need to be sure that the users and products we&#39;re talking about are real, and that somebody hasn&#39;t accidentally changed the order of the parameters being sent to the system.

- when we report usage we&#39;re spending customer&#39;s money we can never, ever get into a situation where we charge them twice. This means that each call to &quot;Add Credit&quot; or &quot;Report Usage and Reserve More&quot; needs to include a unique identifier for the transaction, and the system needs to keep a list of successful transactions for long enough to make sure it&#39;s not a duplicate.


## The Schema

![schema](https://github.com/srmadscience/voltdb-chargingdemo/blob/master/results/chargingdemo_schema.png "Schema")

| Name | Type | Purpose | Partitioning |
| --- | --- | --- | --- |
| user\_table | Table | holds one record per user and the JSON payload. | userid |
| Product\_table | Table | Holds one record per product |   |
| User\_usage\_table | Table | holds information on active reservations of credit by a user for a product. | userid |
| User\_balances | View |  It has one row per user and always contains the user&#39;s current credit, before we allow for reservations in &quot;user\_usage\_table&quot;. | userid |
| User\_recent\_transactions | Table | allows us to spot duplicate transactions and also allows us to track what happened to a specific user during a run | userid |
| allocated\_by\_product | View | How much of each product is currently reserved |   |
| total\_balances | View | A single row listing how much credit the system holds. |   |
| User\_financial\_events | [Export stream](https://docs.voltdb.com/UsingVoltDB/ExportProjectFile.php) | inserted into when we add or spend money | userid |
| finevent | [Export target](https://docs.voltdb.com/UsingVoltDB/ExportProjectFile.php) | Where rows in user\_financial\_events end up - could be kafka, kinesis, HDFS etc | userid |


## How to Run

Create the tesclient job using,

`kubectl create -f testClientJob.yaml -n voltdb` 

The parameters in the YAML file can be edited to change the behavior of simulated traffic, details about the parameters are below,
the same parameters are used in `usersJob.yaml` to set the total number of users and the offset of user ID to be used. 

| Name | Purpose | Example |
| --- | --- | --- |
| hostnames | volt cluster service name | mydb-voltdb-cluster-client.voltdb.svc.cluster.local |
| recordcount | How many users to create | 10000 |
| offset | Used when we want to run multiple copies of ChargingDemo with different users. If recordcount is 2500000 calling a second copy of ChargingDemo with an offset of 3000000 will lead it to creating users in the range 3000000 to 5500000 | 0 |
| tpms | How many transactions per millisecond you want to achieve. Note that a single instance of ChargingDemo will only have a single VoltDB client, which will limit it to around 200 TPMS. To go beyond this you need to run more than one copy. | 4, TPS will be this value * 1000, eg, 4 * 1000 = 4000TPS on volt cluster |
| task | One of:DELETE - deletes users and data,USERS - creates users,TRANSACTIONS - does test run| RUN |
| loblength | How long the arbitrary JSON payload is | 10 |
| durationseconds | How long TRANSACTIONS runs for in seconds | 300 |
| queryseconds | How often we query to check allocations and balances in seconds, along with an arbitrary query of a single user. | 10 |
| initialcredit | How much credit users start with. A high value for this will reduce the number of times AddCredit is called. | 1000 |
| addcreditinterval | How often we add credit based on the number of transactions we are doing - a value of &#39;6&#39; means every 6th transaction will be AddCredit. A value of 0 means that AddCredit is only called for a user when &#39;initialcredit&#39; is run down to zero. | 6 |
