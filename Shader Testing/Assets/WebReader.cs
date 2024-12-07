using UnityEngine;
using System.Collections;
using UnityEngine.Networking;
public class WebReader : MonoBehaviour
{

    public int heartrate = 0;
    void Start() {
        StartCoroutine(GetText());
    }
 
    IEnumerator GetText() {
        string url = "https://dev.pulsoid.net/api/v1/data/heart_rate/latest?response_mode=text_plain_only_heart_rate";
        string authToken = "a6510529-3ac4-4755-b87b-4b9f7fe166c6";

        using(UnityWebRequest request = UnityWebRequest.Get(url)){
            // Set headers
            request.SetRequestHeader("Authorization", "Bearer " + authToken);
            //request.SetRequestHeader("Content-Type", "application/json");

            // Send the request and wait for a response
            yield return request.SendWebRequest();

            if (request.result == UnityWebRequest.Result.Success)
            {
                //Debug.Log("Response: " + request.downloadHandler.text);
                heartrate = int.Parse(request.downloadHandler.text);
            }
            else
            {
                Debug.LogError("Error: " + request.error);
            }
        }
        StartCoroutine(GetText());
    }
}
