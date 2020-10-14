// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "ps2/lit-ps2"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1) //The color of our object
        _Tex ("Texture", 2D) = "white" {}
        _Shininess ("Shininess", Float) = 10 //Shininess
        _SpecColor ("Specular Color", Color) = (1, 1, 1, 1) //Specular highlights color
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" } //We're not rendering any transparent objects
        LOD 200 //Level of detail

        Pass{
            Tags { "LightMode" = "ForwardBase" } //For the first light
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                // make fog work
                #pragma multi_compile_fog
                #include "UnityCG.cginc" //Provides us with light data, camera information, etc

                uniform float4 _LightColor0; //From UnityCG

                sampler2D _Tex; //Used for texture
                float4 _Tex_ST; //For tiling

                uniform float4 _Color; //Use the above variables in here
                uniform float4 _SpecColor;
                uniform float _Shininess;

                struct appdata
                {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                };

                struct v2f
                {
                    float4 pos : POSITION;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                    float4 posWorld : TEXCOORD1;
                    //UNITY_FOG_COORDS(1)
                    //float4 vertex : SV_POSITION;
                };


                v2f vert(appdata v)
                {
                    v2f o;

                    o.posWorld = mul(unity_ObjectToWorld, v.vertex); //Calculate the world position for our point
                    o.normal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz); //Calculate the normal
                    o.pos = UnityObjectToClipPos(v.vertex); //And the position
                    o.uv = TRANSFORM_TEX(v.uv, _Tex);

                    return o;
                }

                fixed4 frag(v2f i) : COLOR
                {
                    fixed4 col = tex2D(_Tex, i.uv);
                    float3 normalDirection = normalize(i.normal);
                    float3 viewDirection = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);

                    float3 vert2LightSource = _WorldSpaceLightPos0.xyz - i.posWorld.xyz;
                    float oneOverDistance = 1.0 / length(vert2LightSource);
                    float attenuation = lerp(1.0, oneOverDistance, _WorldSpaceLightPos0.w); //Optimization for spot lights. This isn't needed if you're just getting started.
                    float3 lightDirection = _WorldSpaceLightPos0.xyz - i.posWorld.xyz * _WorldSpaceLightPos0.w;

                    float3 ambientLighting = UNITY_LIGHTMODEL_AMBIENT.rgb * _Color.rgb; //Ambient component
                    float3 diffuseReflection = attenuation * _LightColor0.rgb * _Color.rgb * max(0.0, dot(normalDirection, lightDirection)); //Diffuse component
                    float3 specularReflection;
                    if (dot(i.normal, lightDirection) < 0.0) //Light on the wrong side - no specular
                    {
                        specularReflection = float3(0.0, 0.0, 0.0);
                	  }
                    else
                    {
                        //Specular component
                        specularReflection = attenuation * _LightColor0.rgb * _SpecColor.rgb * pow(max(0.0, dot(reflect(-lightDirection, normalDirection), viewDirection)), _Shininess);
                    }

                    float3 color = (ambientLighting + diffuseReflection) * tex2D(_Tex, i.uv) + specularReflection; //Texture is not applient on specularReflection
                    return float4(color, 1.0);
                }
                ENDCG
        }
        Pass {
          Tags { "LightMode" = "ForwardAdd" } //For every additional light
        	Blend One One //Additive blending

        	CGPROGRAM
          #pragma vertex vert
          #pragma fragment frag

          #include "UnityCG.cginc" //Provides us with light data, camera information, etc

          uniform float4 _LightColor0; //From UnityCG

          sampler2D _Tex; //Used for texture
          float4 _Tex_ST; //For tiling

          uniform float4 _Color; //Use the above variables in here
          uniform float4 _SpecColor;
          uniform float _Shininess;

          struct appdata
          {
              float4 vertex : POSITION;
              float3 normal : NORMAL;
              float2 uv : TEXCOORD0;
          };

          struct v2f
          {
              float4 pos : POSITION;
              half4 color : COLOR0;
              float3 normal : NORMAL;
              float2 uv : TEXCOORD0;
              float4 posWorld : TEXCOORD1;
          };

          v2f vert(appdata_full v)
          {
              v2f o;

              o.posWorld = mul(unity_ObjectToWorld, v.vertex); //Calculate the world position for our point
              o.normal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz); //Calculate the normal
              o.pos = UnityObjectToClipPos(v.vertex); //And the position
              //o.uv = TRANSFORM_TEX(v.uv, _Tex);

              //Vertex snapping
			float4 snapToPixel = UnityObjectToClipPos(v.vertex);
			float4 vertex = snapToPixel;
			vertex.xyz = snapToPixel.xyz / snapToPixel.w;
			vertex.x = floor(160 * vertex.x) / 160;
			vertex.y = floor(120 * vertex.y) / 120;
			vertex.xyz *= snapToPixel.w;

              //Vertex Lighting
              o.color = float4(ShadeVertexLightsFull(v.vertex, v.normal, 4, true), 1.0);
			  o.color *= v.color;

			  float distance = length(mul(UNITY_MATRIX_MV,v.vertex));
              o.uv = TRANSFORM_TEX(v.texcoord, _Tex);
			  o.uv *= distance + (vertex.w*(UNITY_LIGHTMODEL_AMBIENT.a * 8)) / distance / 2;

              return o;
          }

          fixed4 frag(v2f i) : COLOR
          {
              float3 normalDirection = normalize(i.normal);
              float3 viewDirection = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);

              float3 vert2LightSource = _WorldSpaceLightPos0.xyz - i.posWorld.xyz;
              float oneOverDistance = 1.0 / length(vert2LightSource);
              float attenuation = lerp(1.0, oneOverDistance, _WorldSpaceLightPos0.w); //Optimization for spot lights. This isn't needed if you're just getting started.
              float3 lightDirection = _WorldSpaceLightPos0.xyz - i.posWorld.xyz * _WorldSpaceLightPos0.w;

              float3 diffuseReflection = attenuation * _LightColor0.rgb * _Color.rgb * max(0.0, dot(normalDirection, lightDirection)); //Diffuse component
              float3 specularReflection;
              if (dot(i.normal, lightDirection) < 0.0) //Light on the wrong side - no specular
              {
                specularReflection = float3(0.0, 0.0, 0.0);
              }
              else
              {
                  //Specular component
                  specularReflection = attenuation * _LightColor0.rgb * _SpecColor.rgb * pow(max(0.0, dot(reflect(-lightDirection, normalDirection), viewDirection)), _Shininess);
              }

              float3 color = (diffuseReflection) * tex2D(_Tex, i.uv) + specularReflection; //No ambient component this time
              return float4(color, 1.0);
          }
      ENDCG
        }
    }
}
