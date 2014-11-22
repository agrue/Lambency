module Lambency.Light (
  getLightVarName,
  getLightShaderVars,

  mkLightParams,
  
  spotlight,
  dirlight,
  pointlight,

  addShadowMap,
  
  setAmbient,
  setColor,
  setIntensity,
) where

--------------------------------------------------------------------------------
import Lambency.Texture
import Lambency.Shader
import Lambency.Types

import qualified Data.Map as Map

import Linear.V3
--------------------------------------------------------------------------------

mkLightVar :: String -> ShaderValue -> LightVar a
mkLightVar n v = LightVar (n, v)

mkLightVar3f :: String -> (V3 Float) -> LightVar (V3 Float)
mkLightVar3f n v = mkLightVar n (Vector3Val v)

mkLightVarf :: String -> Float -> LightVar Float
mkLightVarf n f = mkLightVar n (FloatVal f)

mkLightParams :: Vec3f -> Vec3f -> Float -> LightParams
mkLightParams a c i =
  LightParams
  (mkLightVar3f "lightAmbient" a)
  (mkLightVar3f "lightColor" c)
  (mkLightVarf "lightIntensity" i)

getLightShaderVars :: Light -> ShaderMap
getLightShaderVars (Light params ty _) =
  let mkShdrVarPair :: LightVar a -> (String, ShaderValue)
      mkShdrVarPair (LightVar x) = x

      getTypeVars (SpotLight x y z) =
        [mkShdrVarPair x, mkShdrVarPair y, mkShdrVarPair z]
      getTypeVars (DirectionalLight dir) = [mkShdrVarPair dir]
      getTypeVars (PointLight pos) = [mkShdrVarPair pos]

      getParamVars (LightParams a c i) =
        [mkShdrVarPair a, mkShdrVarPair c, mkShdrVarPair i]
  in
   Map.fromList $ getTypeVars ty ++ getParamVars params

spotlight :: LightParams -> Vec3f -> Vec3f -> Float -> Light
spotlight params pos dir ang =
  Light {
    lightParams = params,
    lightType =
      SpotLight
      (mkLightVar3f "spotlightDir" dir)
      (mkLightVar3f "spotlightPos" pos)
      (mkLightVarf "spotlightCosCutoff" $ cos ang),
    lightShadowMap = Nothing
  }

dirlight :: LightParams -> Vec3f -> Light
dirlight params dir =
  Light {
    lightParams = params,
    lightType = DirectionalLight (mkLightVar3f "dirlightDir" dir),
    lightShadowMap = Nothing
  }

pointlight :: LightParams -> Vec3f -> Light
pointlight params pos =
  Light {
    lightParams = params,
    lightType = PointLight (mkLightVar3f "spotlightPos" pos),
    lightShadowMap = Nothing
  }

addShadowMap :: Light -> IO (Light)
addShadowMap l = do
  depthTex <- createDepthTexture
  return $ l { lightShadowMap = (Just $ ShadowMap depthTex) }

setAmbient :: Vec3f -> Light -> Light
setAmbient color (Light params lightTy shadow) =
  let newColor = (mkLightVar3f "lightAmbient" color)
  in Light (params { ambientColor = newColor}) lightTy shadow

setColor :: Vec3f -> Light -> Light
setColor color (Light params lightTy shadow) =
  let newColor = (mkLightVar3f "lightColor" color)
  in Light (params { lightColor = newColor}) lightTy shadow

setIntensity :: Float -> Light -> Light
setIntensity intensity (Light params lightTy shadow) =
  let newi = (mkLightVarf "lightIntensity" intensity)
  in Light (params { lightIntensity = newi}) lightTy shadow
