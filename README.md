# iqas-pipelines

A maven project to easily develop new QoOPipelines for the iQAS platform.

## The iQAS ecosystem

In total, 5 Github projects form the iQAS ecosystem:
1. [iqas-platform](https://github.com/antoineauger/iqas-platform) <br/>The QoO-aware platform that allows consumers to integrate many observation sources, submit requests with QoO constraints and visualize QoO in real-time.
2. [virtual-sensor-container](https://github.com/antoineauger/virtual-sensor-container) <br/>A shippable Virtual Sensor Container (VSC) Docker image for the iQAS platform. VSCs allow to generate observations at random, from file, or to retrieve them from the Web.
3. [virtual-app-consumer](https://github.com/antoineauger/virtual-app-consumer) <br/>A shippable Virtual Application Consumers (VAC) Docker image for the iQAS platform. VACs allow to emulate fake consumers that submit iQAS requests and consume observations while logging the perceived QoO in real-time.
4. [iqas-ontology](https://github.com/antoineauger/iqas-ontology) <br/>Ontological model and examples for the QoOonto ontology, the core ontology used by iQAS.
5. [iqas-pipelines](https://github.com/antoineauger/iqas-pipelines) (this project)<br/>An example of a custom-developed QoO Pipeline for the iQAS platform.

## System requirements

* Java (`1.8`)
* Apache Maven (`3.3.9`)

## Usage

1. Download, configure and build the iQAS platform. See instructions [here](https://github.com/antoineauger/iqas-platform).
2. Locate the "all-in-one" jar file that has been output when you compiled the iQAS platform.<br/>Generally, it is located at `$IQAS_DIR/target/iqas-platform-1.0-SNAPSHOT-allinone.jar`
3. Run the following command:
    ```
    mvn install:install-file \
       -Dfile=path_to_all_in_one_jar/iqas-platform-1.0-SNAPSHOT-allinone.jar \
       -DgroupId=fr.isae.iqas \
       -DartifactId=iqas-platform \
       -Dversion=1.0-SNAPSHOT \
       -Dpackaging=jar \
    -DgeneratePom=true
    ```
4. Now, you should be able to create a new maven project with the following dependency:<br/>
    ```
    <dependencies>
        <dependency>
            <groupId>fr.isae.iqas</groupId>
            <artifactId>iqas-platform</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>
    </dependencies>
    ```
5. Copy-paste the minimal following template. You can now define the logic for your QoO Pipeline.
    If needed, you may have a look to the QoO Pipelines that have already been defined within the iQAS platform (IngestPipeline`, `OutputPipeline`, etc.).
    ```java
    import akka.stream.FlowShape;
    import akka.stream.Graph;
    import akka.stream.Materializer;
    import akka.stream.javadsl.Flow;
    import akka.stream.javadsl.GraphDSL;
    import com.fasterxml.jackson.databind.ObjectMapper;
    import com.fasterxml.jackson.databind.SerializationFeature;
    import fr.isae.iqas.model.observation.ObservationLevel;
    import fr.isae.iqas.model.observation.RawData;
    import fr.isae.iqas.pipelines.AbstractPipeline;
    import fr.isae.iqas.pipelines.IPipeline;
    import fr.isae.iqas.pipelines.mechanisms.CloneSameValueGS;
    import org.apache.kafka.clients.consumer.ConsumerRecord;
    import org.apache.kafka.clients.producer.ProducerRecord;
    import org.json.JSONObject;
    
    import static fr.isae.iqas.model.request.Operator.NONE;
    
    public class MyQoOPipeline extends AbstractPipeline implements IPipeline {
    
        public MyQoOPipeline() {
            super("My QoO Pipeline", "MyQoOPipeline", true);
            addSupportedOperator(NONE);
            setParameter("test_param", String.valueOf(1), true);
        }
    
        @Override
        public Graph<FlowShape<ConsumerRecord<byte[], String>, ProducerRecord<byte[], String>>, Materializer> getPipelineGraph() {
    
            final ObservationLevel askedLevelFinal = getAskedLevel();
            Graph runnableGraph = GraphDSL
                    .create(builder -> {
    
                        // ################################# YOUR CODE GOES HERE #################################
    
                        final FlowShape<ConsumerRecord, RawData> consumRecordToRawData = builder.add(
                                Flow.of(ConsumerRecord.class).map(r -> {
                                    JSONObject sensorDataObject = new JSONObject(r.value().toString());
                                    return new RawData(
                                            sensorDataObject.getString("date"),
                                            sensorDataObject.getString("value"),
                                            sensorDataObject.getString("producer"),
                                            sensorDataObject.getString("timestamps"));
                                })
                        );
    
                        final FlowShape<RawData, ProducerRecord> rawDataToProdRecord = builder.add(
                                Flow.of(RawData.class).map(r -> {
                                    ObjectMapper mapper = new ObjectMapper();
                                    mapper.enable(SerializationFeature.INDENT_OUTPUT);
                                    return new ProducerRecord<byte[], String>(getTopicToPublish(), mapper.writeValueAsString(r));
                                })
                        );
    
                        builder.from(consumRecordToRawData.out())
                                .via(builder.add(new CloneSameValueGS<RawData>(Integer.valueOf(getParams().get("nb_copies")))))
                                .toInlet(rawDataToProdRecord.in());
    
                        // ################################# END OF YOUR CODE #################################
    
                        return new FlowShape<>(consumRecordToRawData.in(), rawDataToProdRecord.out());
    
                    });
    
            return runnableGraph;
        }
    
        @Override
        public String getPipelineID() {
            return getClass().getSimpleName();
        }
    
    }
    ````
6. Compile your newly-defined QoO Pipeline:
    ```
    mvn -T C2.0 clean install -DskipTests 
    ```
7. Locate the `.class` file corresponding to your QoO Pipeline. It should be in `$PIPELINE_DIR/target/classes/my_pipeline.class` 
8. Copy and paste this `.class` file within the "qoo_pipelines_dir" directory of the iQAS platform.
9. Register your new QoO Pipeline to the iQAS platform at [http://\[api_gateway_endpoint_address\]:\[api_gateway_endpoint_port\]/configuration](#)

## Acknowledgments

The iQAS platform have been developed during the PhD thesis of [Antoine Auger](https://personnel.isae-supaero.fr/antoine-auger/?lang=en) at ISAE-SUPAERO (2014-2017).

This research was supported in part by the French Ministry of Defence through financial support of the Direction Générale de l’Armement (DGA). 

![banniere](https://github.com/antoineauger/iqas-platform/blob/master/src/main/resources/web/figures/banniere.png?raw=true "Banniere")
