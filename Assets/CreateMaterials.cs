using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif
using System.Collections;
using System.IO;
using System;

#pragma warning disable 649

namespace UnityEditor
{
#if UNITY_EDITOR
    class CreateMaterials : ScriptableWizard
    {
        public static string shaderName = "Universal Render Pipeline/Lit";

        public Texture2D metallic;
        public Texture2D ao;
        public Texture2D height;
        public Texture2D smoothness;


        [MenuItem("Tools/TerrainMaskTexture", false, 2000)]
        static void CreateWizard()
        {
            ScriptableWizard.DisplayWizard<CreateMaterials>("Create Texture");
        }
        void OnWizardCreate()
        {
            Texture2D tex1 = metallic;
            Texture2D tex2 = ao;
            Texture2D tex3 = height;
            Texture2D tex4 = smoothness;

            // Create a black texture to use as a default
            Texture2D blackTexture = new Texture2D(1, 1, TextureFormat.RGBA32, false);
            blackTexture.SetPixel(0, 0, Color.black);
            blackTexture.Apply();

            // Replace null textures with the black texture
            tex1 = tex1 ?? blackTexture;
            tex2 = tex2 ?? blackTexture;
            tex3 = tex3 ?? blackTexture;
            tex4 = tex4 ?? blackTexture;

            // Determine the smallest texture dimensions
            int minWidth = Mathf.Min(tex1.width, tex2.width, tex3.width, tex4.width);
            int minHeight = Mathf.Min(tex1.height, tex2.height, tex3.height, tex4.height);

            // Create the new texture
            Texture2D combinedTexture = new Texture2D(minWidth, minHeight, TextureFormat.RGBA32, false);

            // Resample the larger textures to match the dimensions of the smallest texture
            tex1 = ResampleTexture(tex1, minWidth, minHeight);
            tex2 = ResampleTexture(tex2, minWidth, minHeight);
            tex3 = ResampleTexture(tex3, minWidth, minHeight);
            tex4 = ResampleTexture(tex4, minWidth, minHeight);

            // Copy the channels from each input texture to the combined texture
            for (int x = 0; x < minWidth; x++)
            {
                for (int y = 0; y < minHeight; y++)
                {
                    Color color = new Color(tex1.GetPixel(x, y).r, tex2.GetPixel(x, y).g,
                                            tex3.GetPixel(x, y).b, tex4.GetPixel(x, y).a);
                    combinedTexture.SetPixel(x, y, color);
                }
            }

            // Apply the changes and return the combined texture
            combinedTexture.Apply();
            string folderPath = EditorUtility.OpenFolderPanel("Select folder", "", "");

            AssetDatabase.CreateAsset(combinedTexture, folderPath + "/" + tex1.name + ".png");
        }

        static Texture2D ResampleTexture(Texture2D tex, int newWidth, int newHeight)
        {
            Texture2D resampledTex = new Texture2D(newWidth, newHeight, TextureFormat.RGBA32, false);
            resampledTex.filterMode = FilterMode.Trilinear;
            Graphics.ConvertTexture(tex, resampledTex);
            return resampledTex;
        }


        [MenuItem("Tools/CreateMaterials", false, 2000)]
        static void CreateMaterial()
        {
            UnityEngine.Object[] objs = Selection.objects;

            for (int i = 0; i < objs.Length; i++)
            {
                string objpath = AssetDatabase.GetAssetPath(objs[i]);
                string path = objpath.Split(".")[0];
                //Debug.Log(objs[i].GetType() + " " + path);
                if (objs[i].GetType() == typeof(UnityEngine.Texture2D))
                {

                    var material = new Material(Shader.Find(shaderName));
                    material.SetTexture("_BaseMap", (Texture2D)AssetDatabase.LoadAssetAtPath(objpath, typeof(Texture2D)));
                    AssetDatabase.CreateAsset(material, path + ".mat");
                }
            }
        }

        [MenuItem("Tools/FlipTextures", false, 2000)]
        public static void FlipTexture2DHorizontally()
        {
            UnityEngine.Object[] objs = Selection.objects;

            for (int i = 0; i < objs.Length; i++)
            {
                string objpath = AssetDatabase.GetAssetPath(objs[i]);
                string path = objpath.Split(".")[0];
                //Debug.Log(objs[i].GetType() + " " + path);
                if (objs[i].GetType() == typeof(UnityEngine.Texture2D))
                {
                    Texture2D originalTexture = (Texture2D)AssetDatabase.LoadAssetAtPath(objpath, typeof(Texture2D));
                    int width = originalTexture.width;
                    int height = originalTexture.height;

                    // Create a new texture with the same dimensions as the original
                    Texture2D flippedTexture = new Texture2D(width, height, TextureFormat.RGBA32, false);

                    // Copy the original texture's pixels to the flipped texture, but flip them horizontally
                    for (int x = 0; x < width; x++)
                    {
                        for (int y = 0; y < height; y++)
                        {
                            Color pixel = originalTexture.GetPixel(x, y);
                            flippedTexture.SetPixel(width - x - 1, y, pixel);
                        }
                    }

                    // Apply changes and return the flipped texture
                    flippedTexture.Apply();
                    AssetDatabase.SaveAssets();
                }
                //var material = new Material(Shader.Find("Toon4"));
                //
            }
        }
    }
#endif
}