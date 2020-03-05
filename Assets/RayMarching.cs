using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
[AddComponentMenu("Effects/Raymarch (Generic)")]
public class RayMarching : SceneViewFilter {

    [Range(0.0f, 1.0f)]
    public float param;

    public GameObject object1;
    public GameObject object2;

    [SerializeField]
    private Shader rayMarchingShader;

    private int frame = 0;

    public Material rayMarchingMaterial
    {
        get
        {
            if (!_rayMarchingMaterial && rayMarchingShader)
            {
                _rayMarchingMaterial = new Material(rayMarchingShader);
                _rayMarchingMaterial.hideFlags = HideFlags.HideAndDontSave;
            }
            return _rayMarchingMaterial;
        }
    }
    private Material _rayMarchingMaterial;

    public Camera CurrentCamera
    {
        get
        {
            if (!_CurrentCamera) _CurrentCamera = GetComponent<Camera>();
            return _CurrentCamera;
        }
    }
    private Camera _CurrentCamera;

    private Matrix4x4 GetFrustumCorners(Camera cam)
    {
        float camFov = cam.fieldOfView;
        float camAspect = cam.aspect;
        Matrix4x4 frustumCorners = Matrix4x4.identity;
        float fovWHalf = camFov * 0.5f;
        float tan_fov = Mathf.Tan(fovWHalf * Mathf.Deg2Rad);
        Vector3 toRight = Vector3.right * tan_fov * camAspect;
        Vector3 toTop = Vector3.up * tan_fov;
        Vector3 topLeft = (-Vector3.forward - toRight + toTop);
        Vector3 topRight = (-Vector3.forward + toRight + toTop);
        Vector3 bottomRight = (-Vector3.forward + toRight - toTop);
        Vector3 bottomLeft = (-Vector3.forward - toRight - toTop);
        frustumCorners.SetRow(0, topLeft);
        frustumCorners.SetRow(1, topRight);
        frustumCorners.SetRow(2, bottomRight);
        frustumCorners.SetRow(3, bottomLeft);
        return frustumCorners;
    }

    static void CustomGraphicsBlit(RenderTexture source, RenderTexture dest, Material fxMaterial, int passNr)
    {
        RenderTexture.active = dest;
        fxMaterial.SetTexture("_MainTex", source);
        GL.PushMatrix();
        GL.LoadOrtho();
        fxMaterial.SetPass(passNr);
        GL.Begin(GL.QUADS);
        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f); // BL
        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f); // BR
        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f); // TR
        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f); // TL
        GL.End();
        GL.PopMatrix();
    }

    [ImageEffectOpaque]
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        rayMarchingMaterial.SetMatrix("_FrustumCornersES", GetFrustumCorners(CurrentCamera));
        rayMarchingMaterial.SetMatrix("_CameraInvViewMatrix", CurrentCamera.cameraToWorldMatrix);
        rayMarchingMaterial.SetVector("_CameraWS", CurrentCamera.transform.position);
        rayMarchingMaterial.SetFloat("_Param", param);
        rayMarchingMaterial.SetVector("_Object1", object1.transform.position);
        rayMarchingMaterial.SetVector("_Object2", object2.transform.position);
        CustomGraphicsBlit(source, destination, rayMarchingMaterial, 0);
    }

}