using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AudioHandler : MonoBehaviour
{
    public static AudioHandler instance;

    [SerializeField]
    private float fullVolume = 1;

    [SerializeField]
    private float volScaleSpeed = 5 ;
    private float currVolume = 1;
    public List<AudioSource> sounds;
    // Start is called before the first frame update
    [SerializeField]
    private AudioSource whispers;

    private bool louder = false;
    void Start()
    {
        instance = this;
    }

    public void Update(){
        if(louder && currVolume < fullVolume){
            currVolume += Time.deltaTime * volScaleSpeed;
        }
        if(!louder && currVolume > 0){
            currVolume -= Time.deltaTime * volScaleSpeed;
        }
        whispers.volume = currVolume;
    }

    public void PlayHeartbeat(Vector3 position){
        AudioSource spawnedSound = Instantiate(sounds[0], position, Quaternion.identity);
        //spawnedSound.Play();
        StartCoroutine(DeleteSound(spawnedSound));
    }

    public void PlayWhispers(bool mute, float dist, Vector3 camPos, Vector3 forwardDir){
        louder = !mute;
        whispers.transform.position = camPos - forwardDir * dist;
    }

    IEnumerator DeleteSound(AudioSource ToDelete){
        yield return new WaitForSeconds(2f);
        Destroy(ToDelete.gameObject);
    }
    
}
