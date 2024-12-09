using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BoidHandler : MonoBehaviour
{
    public DepthPostEffects postEffectsController;

    public Camera playerCam;

    public GameObject stalkPoint;
    private const float G = 500f;

    public int bpm = 100;

    public GameObject boidObject;

    public GameObject[] body;

    BodyProperty[] bp;

    public int numberOfSphere = 50;

    public float startSpawnDistance = 50;

    public float speed;

    public float maxVelocity;
    private float effectiveMaxVelocity;

    public float maxRetreatingVelocity;

    public float cohesionRadius;
    public float cohesionStrength;
    public float alignmentRadius;
    public float alignmentStrength;
    public float avoidanceRadius;
    public float avoidanceStrength;

    public float centerizeDistThreshold;

    public float recenterStrength;

    public float visionDistance = 15;

    
    public float stalkSpeed;

    public float retreatSpeed;

    public float maxRetreatDistance;
    public Vector3 centerPoint;

    public bool visible;

    public Vector2 scarinessSmoothingVals;
    public Vector2 scarinessMinMax;

    public bool drawDebugLines;

    TrailRenderer trailRenderer;

    public Material CircleDeformMat;

    public GameObject light;
    public Vector2 lightWaitTimes;

    private bool inVision = false;

    struct BodyProperty // why struct?

    {                   // https://learn.microsoft.com/en-us/dotnet/standard/design-guidelines/choosing-between-class-and-struct

        public Vector3 velocity;

        public Vector3 acceleration;

        public bool retreating;

        public Material material;
        

    }

    Vector3 GetRandomDirectionXZ()
    {
        // Generate a random angle in radians
        float angle = Random.Range(0f, Mathf.PI * 2f);

        // Calculate the X and Z components using cosine and sine
        float x = Mathf.Cos(angle);
        float z = Mathf.Sin(angle);

        // Return the vector in the XZ plane
        return new Vector3(x, 0f, z);
    }

    void RestartBoidPosition(GameObject g){
        Vector3 randDir = GetRandomDirectionXZ() + new Vector3(0, Random.Range(-0.3f,0.3f), 0);
        g.transform.position = playerCam.transform.position + randDir.normalized * startSpawnDistance * (float)Random.Range(1f,3f);
    }



    void Start()

    {

        // Just like GO, computer should know how many room for struct is required:

        bp = new BodyProperty[numberOfSphere];

        body = new GameObject[numberOfSphere];


        // Loop generating the gameobject and assign initial conditions (type, position, (mass/velocity/acceleration)

        for (int i = 0; i < numberOfSphere; i++)

        {          

            // Our gameobjects are created here:

            body[i] = Instantiate(boidObject, new Vector3(0,0,0), Quaternion.identity); // why sphere? try different options.
            //set up custom material
            Material newMaterial = new Material(Shader.Find("Unlit/Color"));
            int temp2 = i + 1;
            float rCol = (float)(((float)temp2%10))/10;
            float gCol = (float)(((float)(temp2/10)%10))/10;
            float bCol = (float)(((float)(temp2/100)%10))/10;
            Color newColor = new Color(rCol,gCol,bCol,1);
            /*
            if(i == 0){
                newColor = new Color(1,0.9f,0,1);
            }else if(i == 1){
                newColor = new Color(1,0.2f,0,1);
            }else if(i == 2){
                newColor = new Color(1,0.5f,0,1);
            }*/
            

            // Set properties on the material
            newMaterial.SetColor("_Color", newColor);

            postEffectsController.BoidColorList.Add(newColor);

            //if(i == 0){
            body[i].GetComponent<Renderer>().material = newMaterial;
            bp[i].material = newMaterial;
            //}

            // https://docs.unity3d.com/ScriptReference/GameObject.CreatePrimitive.html


            // initial conditions

            float r = 50f;

            // position is (x,y,z). In this case, I want to plot them on the circle with r


            // ******** Fill in this part ********


            //body[i].transform.position = new Vector3( Random.Range(10,-10), Random.Range(10,-10), 180);
            RestartBoidPosition(body[i]);

            // z = 180 to see this happen in front of me. Try something else (randomize) too.


            bp[i].velocity = Random.insideUnitSphere * speed;
            bp[i].retreating = false;

            // Init Trail
/*
            if(i != 0){
                 trailRenderer = body[i].AddComponent<TrailRenderer>();

            // Configure the TrailRenderer's properties

            trailRenderer.time = 5.0f;  // Duration of the trail

            trailRenderer.startWidth = 0.5f;  // Width of the trail at the start

            trailRenderer.endWidth = 0.1f;    // Width of the trail at the end

            // a material to the trail

            trailRenderer.material = new Material(Shader.Find("Sprites/Default"));

            // Set the trail color over time

            Gradient gradient = new Gradient();

            gradient.SetKeys(

                new GradientColorKey[] { new GradientColorKey(Color.white, 0.0f), new GradientColorKey(new Color (Mathf.Cos(Mathf.PI * 2 / numberOfSphere * i), Mathf.Sin(Mathf.PI * 2 / numberOfSphere * i), Mathf.Tan(Mathf.PI * 2 / numberOfSphere * i)), 0.80f) },

                new GradientAlphaKey[] { new GradientAlphaKey(1.0f, 0.0f), new GradientAlphaKey(0.0f, 1.0f) }

            );

            trailRenderer.colorGradient = gradient;
            }*/
           


        }

    }

    float timePassed = 0;
    bool step = false;
    void FixedUpdate()
    {
        step = false;
        bpm = WebReader.instance.heartrate;
        timePassed += Time.deltaTime;
        if(timePassed >= 60f/bpm){
            timePassed -= 60f/bpm;
            step = true;
            AudioHandler.instance.PlayHeartbeat(playerCam.transform.position);
            effectiveMaxVelocity = maxVelocity * ((float)bpm / 100f);
            
            
        }
        float minDist = 1000;

        for (int i = 0; i < numberOfSphere; i++)

        {  

            bp[i].acceleration = Vector3.zero;
        }

        inVision = false;
        for (int i = 0; i < numberOfSphere; i++)
        {
            float dist = Vector3.Distance(body[i].transform.position, playerCam.transform.position);
            
            //set scariness based on distance
            if(IsPositionInView(playerCam, body[i].transform.position) && 
                Vector3.Distance(body[i].transform.position, playerCam.transform.position) < visionDistance){
                inVision = true;
                if(dist < minDist){
                    minDist = dist;
                }  
            }
            if(bp[i].retreating == false){
                bp[i].retreating = IsPositionInView(playerCam, body[i].transform.position) && 
                Vector3.Distance(body[i].transform.position, playerCam.transform.position) < visionDistance;
            }
            
            

            bp[i].acceleration += Cohesion(body[i]) * cohesionStrength;
            bp[i].acceleration += Alignment(body[i], bp[i].velocity) * alignmentStrength;
            bp[i].acceleration += Avoidance(body[i]) * avoidanceStrength;
            //bp[i].acceleration += Recenter(body[i]) * recenterStrength;

            if(Vector3.Distance(body[i].transform.position, playerCam.transform.position) >  maxRetreatDistance && bp[i].retreating){
                bp[i].retreating = false;
                RestartBoidPosition(body[i]);

            }

            //if boid inside player
            if(Vector3.Distance(body[i].transform.position, playerCam.transform.position) < 0.3f){
                bp[i].retreating = false;
                RestartBoidPosition(body[i]);
            }

            if(bp[i].retreating){
                bp[i].acceleration += -Stalk(body[i]) * retreatSpeed;
            }else{
                bp[i].acceleration += Stalk(body[i]) * stalkSpeed;
            }
            

            if (drawDebugLines) {
                Debug.DrawLine(body[i].transform.position, body[i].transform.position + bp[i].acceleration, Color.blue);
            }
            

            bp[i].velocity += bp[i].acceleration * Time.deltaTime;

            //clamp velocity
            if(bp[i].velocity.magnitude > effectiveMaxVelocity && !bp[i].retreating){
                bp[i].velocity = bp[i].velocity.normalized * effectiveMaxVelocity;
            }

            if(bp[i].velocity.magnitude > maxRetreatingVelocity && bp[i].retreating){
                bp[i].velocity = bp[i].velocity.normalized * maxRetreatingVelocity;
            }
            //Debug.Log(bp[i].velocity.magnitude);
            if(step){
                StartCoroutine(LerpBoid(body[i], body[i].transform.position, body[i].transform.position + bp[i].velocity * 60f/bpm, 30f/bpm));
            }
            

        }

        UpdateDeformMesh(minDist);


        if(inVision){
            AudioHandler.instance.PlayWhispers(false, minDist, playerCam.transform.position, playerCam.transform.forward);
            //this feature looked bad
            //StartCoroutine(LightBlink());
        }else{
            AudioHandler.instance.PlayWhispers(true, minDist, playerCam.transform.position, playerCam.transform.forward);
        }
        /*
        Camera.main.transform.position = body[0].transform.position;
        Camera.main.transform.LookAt(body[0].transform.position + bp[0].velocity);*/

        //update metaball positions
        /*
        List<PostEffectsController.MetaballParameters> m = new List<PostEffectsController.MetaballParameters>();
        for(int i = 0; i<body.Length; i++){
            m.Add(new PostEffectsController.MetaballParameters(body[i].transform.position, 2f));
        }
        postEffectsController.metaballs = m;*/

    }

    private IEnumerator LerpBoid(GameObject boidBody, Vector3 startPos, Vector3 endPos, float time){
        float passedTime = 0;
        while(passedTime < time){
            passedTime += Time.deltaTime;
            boidBody.transform.position = Vector3.Lerp(startPos, endPos, passedTime/time);
            yield return 0;
        }
    }

    private void UpdateDeformMesh(float minDist){
        float smoothedDist = 1-RatioClamp(scarinessSmoothingVals.x, scarinessSmoothingVals.y, minDist);
        float distortionVal = Mathf.Lerp(scarinessMinMax.x, scarinessMinMax.y, smoothedDist);
        CircleDeformMat.SetFloat("_DistortionStrength", distortionVal);
    }

    float RatioClamp(float min, float max, float t)
    {
        if (t <= min) return 0f;
        if (t >= max) return 1f;
        return (t - min) / (max - min);
    }


    // Gravity Fuction to finish

    private Vector3 Cohesion (GameObject a)
    {
        Vector3 center = Vector3.zero;
        int count = 0;

        for(int i = 0; i < numberOfSphere; i++){
            if (body[i] != a && Vector3.Distance(body[i].transform.position,a.transform.position) < cohesionRadius)
            {
                center += body[i].transform.position;
                count++;
            }

        }
         
        if (count > 0)
        {
            center /= count;
            return (center - a.transform.position).normalized * speed;
        }

        return Vector3.zero;

    }

    private Vector3 Alignment(GameObject a, Vector3 v){
        Vector3 alignmentVector = Vector3.zero;
        int count = 0;

        for(int i = 0; i < numberOfSphere; i++)
        {
            if (body[i] != a && Vector3.Distance(a.transform.position, body[i].transform.position) < alignmentRadius)
            {
                alignmentVector += bp[i].velocity;
                count++;
            }
        }

        if (count > 0)
        {
            alignmentVector /= count;
            return (alignmentVector.normalized * speed - v);
        }

        return Vector3.zero;
    }

    private Vector3 Avoidance(GameObject a)
    {
        Vector3 avoidanceVector = Vector3.zero;

        for(int i = 0; i < numberOfSphere; i++)
        {
            
            if (body[i] != a && Vector3.Distance(a.transform.position, body[i].transform.position) < avoidanceRadius)
            {
                avoidanceVector += (a.transform.position - body[i].transform.position);
            }
        }
        //add player to avoidance
        if (Vector3.Distance(playerCam.transform.position, a.transform.position) < avoidanceRadius)
            {
                avoidanceVector += (playerCam.transform.position - a.transform.position);
            }

        return avoidanceVector.normalized * speed;
    }

    private Vector3 Recenter(GameObject a)
    {
        Vector3 centerDirection =  centerPoint - a.transform.position;
        float dist = Vector3.Distance(a.transform.position, centerPoint);

        if(dist > centerizeDistThreshold){
            return centerDirection.normalized * speed;
        }
        return Vector3.zero;
    }

    private Vector3 Stalk(GameObject a){
        Vector3 playerDirection = stalkPoint.transform.position - a.transform.position;
        return playerDirection;
    }

    private bool IsPositionInView(Camera camera, Vector3 worldPosition)
    {
        Vector3 viewportPoint = camera.WorldToViewportPoint(worldPosition);

        // Check if the position is in front of the camera and within the viewport boundaries
        return viewportPoint.z > 0 && viewportPoint.x >= 0 && viewportPoint.x <= 1 && viewportPoint.y >= 0 && viewportPoint.y <= 1;
    }

    private IEnumerator LightBlink(){
        yield return new WaitForSeconds(lightWaitTimes.x);
        light.GetComponent<Light>().intensity /= 2;
        yield return new WaitForSeconds(lightWaitTimes.y);
        light.GetComponent<Light>().intensity *= 2;
    }

   

}
