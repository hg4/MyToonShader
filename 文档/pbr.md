## 一、PBR核心理论和光学原理

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-c95ef0b0e9faa1c13132d3f216480075_1440w.jpg)



### A.基于物理的渲染核心理论

**微平面理论：**将物体表面建模成微观上随机凹凸不平的小平面，实际渲染管线中使用粗糙度贴图来反应这种微观几何现象的统计学表现，在微观尺度上，表面越粗糙，反射越模糊，表面越光滑，反射越集中。

**能量守恒**:出射光能量不能超过入射光，并且镜面反射区域面积增加，整体亮度要下降，因此传统的phong模型并不满足能量守恒。

**基于F0建模的菲涅尔反射**：菲涅尔反射定义了反射/折射与视点角度的关系，如果你站在湖边，低头看脚下的水，你会发现水是透明的，反射不是特别强烈；如果你看远处的湖面，你会发现水并不是透明的，但反射非常强烈。这就是“菲涅尔效应”。菲涅尔反射描述了反射与折射光的比率，我们定义F0为0度角入射（垂直表面入射）的菲涅尔反射率，其余任意角度的反射率可以根据F0和入射角计算得到。在微平面模型下，用于菲涅尔效应计算的是每个微平面的法向量和入射光角度而并非宏观的。

**线性光照空间：**基于物理渲染的数学公式都是基于线性空间，而输入的8sRGB贴图往往经过了gamma校正来存储，在读入图像后需要将图像从非线性空间转换为线性空间，才能得到正确结果。

**色调映射：**pbr光照的数值往往是基于HDR场景的强度，为了将光照结果从HDR转换到显示器能显示的LDR，需要进行色调映射。

**基于真实世界测量的材质参数**：pbr所用的材质参数往往基于真实世界测量。菲涅尔反射率代表了材质的镜面反射颜色和强度，非金属的镜面反射颜色为非彩色，金属为彩色。

**光照与材质解耦**：pbr渲染的核心原则就是要实现光照和材质的解耦，以模拟真实的光照现象，这也是和传统光照模型的最大区别。传统光照模型往往需要使用漫反射贴图、镜面反射贴图等等，贴图中既反映了材质也反映了一定程度的光照，使用时调整困难。而pbr渲染使用albedo纹理，不包含传统的漫反射纹理中常有的细小阴影和深色裂纹，只反映表面颜色，镜面反射根据粗糙度、金属度贴图等直接计算。



### **B.渲染与物理光学**

##### **1.相速度与折射率：**

在波动光学中光被建模成电磁横波，电场与磁场垂直传播方向进行震荡。

磁场矢量的长度和电场矢量长度之比固定，比率等于相速度。

光传播到不同介质交界处时，原始光波和新的光波相速度的比率定义了介质的光学属性，即折射率**n**。

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-ecea176752ab0ea4370f54f972fb5ad2_1440w.jpg)

##### **2.复折射率**：

引入系数$\boldsymbol\kappa$表示介质将光转为其他形式能量的吸收性，**n**和$\boldsymbol \kappa$组成了一个复数的虚部和实部，称为复折射率。复折射率的实部度量了物质如何影响光速，虚部确定了光在传播时被吸收的程度。

特定材质对光具有选择性吸收，其本质是光波频率和该材质原子中电子振动的频率相匹配。

##### **3.折射发生条件**：

在表面发生折射需要在小于单一波长的距离内发生折射率的突然变化。折射率缓慢变化不会导致光线分离，只会导致传播路径扭曲，一般产生在空气密度因温度变化时，如海市蜃楼和热形变。

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-0103565c50037e8ca871993c419d69aa_1440w.jpg)

##### **4.物质对吸收和散射的特性组合决定其外观**：

散射决定了介质的浑浊程度，高散射产生不透明外观。吸收决定了材质的外观颜色。

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-d3ac5ac91eff21a435ecb067100ead0e_1440w.jpg)



### **C.渲染与几何光学**

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-b855ab10a0b290f023898332e0360dce_1440w.jpg)

##### **1.光与物体表面产生的现象分类：**

**反射**：单指镜面反射specular。镜面反射占入射光线的比率可由菲涅尔方程计算，集中度由粗糙度决定。

**折射：**折射产生的最终现象可以分为散射和吸收，散射可以分为漫反射和次表面散射，次表面散射又包括透射。吸收产生最终的现象是由于部分光色波长被吸收，使漫反射出来的光反映了物体表面的固有色。

##### **2.不同物质与光的交互总结：**

**金属**：金属没有折射，折射进去的光都被自由电子吸收，因此不存在漫反射和散射。金属的镜面反射三通道RGB数值不相同。

**非金属：**即电介质，有反射、折射，一般考虑镜面反射和漫反射。

##### **3.微平面理论**：

将物体表面建模成凹凸不平的微小平面，采用粗糙度数值进行衡量，**粗糙度反映了能正确将入射光反射到视点方向的微平面的统计学比率**。粗糙度越大，反射越模糊。

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-a8a697e4bb8207c0bf1269957abb1df1_1440w.jpg)

##### **4.菲涅尔效应：**

菲涅尔效应即描述视线垂直于表面时反射较弱，而当视线非垂直表面时，夹角越小，反射越明显的一种现象。

需要注意的是，**我们在宏观层面看到的菲涅尔效应实际上是微观层面微平面菲涅尔效应的平均值。**即影响菲涅尔效应的关键参数在于每个微平面的法向量和入射光线的角度，而不是宏观平面的法向量和入射光线的角度。

不同材质的菲涅尔效应强弱不同，金属反射率大部分角度都保持很高，绝缘体材质如玻璃的菲涅尔效应就很明显。

采用入射角0°时的菲涅尔反射率作为材质的特征反射率F0，对材质的反射属性进行建模。大多数电介质的F0范围为0.02-0.05，导体的范围在0.5以上。

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-653ec95132964d6cefbe5f15a5adf9bc_1440w.jpg)

通用的折射率与F0的关系式如下：
$$
F_0=(\frac{n_1-n_2}{n_1+n_2})^2 \\
假设n_1=1，则有 \\
F_0=(\frac{n-1}{n+1})^2
$$


## 二、迪士尼原则的BRDF与BSDF

### A.迪士尼采用的BRDF可视化方案与工具

MERL 100 BRDF材质库。

BRDF Explorer。迪士尼开发的BRDF模型的可视化工具。

BRDF image SLICE.具体如下所示。$\theta_d$表示光照方向h和视线方向v的夹角？，$\theta_h$表示微平面中间向量的方向？存疑。

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-6a73b235df6d233fa380a7e2d18a4e47_1440w.jpg)



### B.迪士尼对MERL材质数据库的观察结论

漫反射（Diffuse）表示折射（refracted）到表面，经过散射（scattered）和部分吸收（partially absorbed），最终重新出表面出射的光。

通过观察得出掠射逆反射（grazing retroreflection，对应切片图的右下角部分）有明显的着色现象，即可以将掠射逆反射（grazing retroreflection）也看做一种漫反射现象。

粗糙度会对菲涅尔折射造成影响，而一般的漫反射模型如Lambert忽略了这种影响。

这部分再往后具体观察讨论看不懂，先跳过。



### C.迪士尼原则的BRDF

迪士尼的理念是开发一种以艺术导向为原则的易用模型，并不追求严格的物理真实，目的是使美术能用少量且直观的参数和标准化的工作流快速实现真实感的渲染。

迪士尼原则的BRDF（Disney Principled BRDF）核心理念如下：

- 应使用直观的参数，而不是物理类的晦涩参数。
- 参数应尽可能少。
- 参数在其合理范围内应该为0到1。
- 允许参数在有意义时超出正常的合理范围。
- 所有参数组合应尽可能健壮和合理。

##### 1.disney principled BRDF参数：

- baseColor（固有色）：表面颜色，通常由纹理贴图提供。
- subsurface（次表面）：使用次表面近似控制漫反射形状。
- metallic（金属度）：金属（0 = 电介质，1 =金属）。这是两种不同模型之间的线性混合。金属模型没有漫反射成分，并且还具有等于基础色的着色入射镜面反射。
- specular（镜面反射强度）：入射镜面反射量。用于取代折射率。
- specularTint（镜面反射颜色）：对美术控制的让步，用于对基础色（basecolor）的入射镜面反射进行颜色控制。掠射镜面反射仍然是非彩色的。
- roughness（粗糙度）：表面粗糙度，控制漫反射和镜面反射。
- anisotropic（各向异性强度）：各向异性程度。用于控制镜面反射高光的纵横比。（0 =各向同性，1 =最大各向异性。）
- sheen（光泽度）：一种额外的掠射分量（grazing component），主要用于布料。
- sheenTint（光泽颜色）：对sheen（光泽度）的颜色控制。
- clearcoat（清漆强度）：有特殊用途的第二个镜面波瓣（specular lobe）。
- clearcoatGloss（清漆光泽度）：控制透明涂层光泽度，0 = “缎面（satin）”外观，1 = “光泽（gloss）”外观。



##### 2.Disney Principled BRDF的着色模型：

![[公式]](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cequation.svg)

###### 2.1漫反射项diffuse：

![[公式]](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cequation-1602662884268.svg)

其中， $\theta_l$表示法线n和光线方向l的夹角，$\theta_v$表示法线n和视线方向v的夹角，$\theta_d$表示中间向量h和视线方向v的夹角，$F_{D90}=0.5+2*roughness*cos^2\theta_d$

（中间向量h和法向量n的区别，中间向量h是微表面法线向量，一般直接用宏观的半矢量$h=\frac{l+v}{||l+v||}$代替。而法向量n是指宏观的法向量）

disney shader的实现

```
// [Burley 2012, "Physically-Based Shading at Disney"]
float3 Diffuse_Burley_Disney( float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH )
{
	float FD90 = 0.5 + 2 * VoH * VoH * Roughness;
	float FdV = 1 + (FD90 - 1) * Pow5( 1 - NoV );
	float FdL = 1 + (FD90 - 1) * Pow5( 1 - NoL );
	return DiffuseColor * ( (1 / PI) * FdV * FdL );
}
```



###### 2.2法线分布项D

法线分布函数流行的公式为GGX:
$$
NDF_{GGX TR}(n, h, \alpha) = \frac{\alpha^2}{\pi((n \cdot h)^2 (\alpha^2 - 1) + 1)^2}
$$
disney采用的是将Trowbridge-Reitz和Berry的形式推广，定义了一个Generalized-Trowbridge-Reitz，GTR：
$$
D_{GTR}=\frac{c}{(\alpha^2cos^2\theta_h+sin^2\theta_h)^\gamma}
$$
其中$\gamma$=1时为berry分布，$\gamma$=2时为Trowbridge-Reitz分布，shader实现如下：

```
// Generalized-Trowbridge-Reitz distribution
float D_GTR1(float alpha, float dotNH)
{
    float a2 = alpha * alpha;
    float cos2th = dotNH * dotNH;
    float den = (1.0 + (a2 - 1.0) * cos2th);

    return (a2 - 1.0) / (PI * log(a2) * den);
}

float D_GTR2(float alpha, float dotNH)
{
    float a2 = alpha * alpha;
    float cos2th = dotNH * dotNH;
    float den = (1.0 + (a2 - 1.0) * cos2th);

    return a2 / (PI * den * den);
}
```

###### 2.3菲涅尔项F

disney采用Schlick Fresnel进行近似：

![[公式]](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cequation-1602665251804.svg)

当IOR接近1时，schlick近似误差较大，此时建议使用精确的菲涅尔方程。

shader实现：

```
float3 F_Schlick(float HdotV, float3 F0)
{
    return F0 + (1 - F0) * pow(1 - HdotV , 5.0));
}
```



###### 2.4几何遮蔽项G

几何项（Specular G）方面，对于主镜面波瓣（primary specular lobe），Disney参考了 Walter的近似方法，使用Smith GGX导出的G项，并将粗糙度参数进行重映射以减少光泽表面的极端增益，即将α 从[0, 1]重映射到[0.5, 1]，α的值为(0.5 + roughness/2)^2。从而使几何项的粗糙度变化更加平滑，更便于美术人员的使用。

以下为Smith GGX的几何项的表达式：

![[公式]](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cequation-1602665445575.svg)

shader实现：

```glsl
// Smith GGX G项，各项同性版本
float smithG_GGX(float NdotV, float alphaG)
{
    float a = alphaG * alphaG;
    float b = NdotV * NdotV;
    return 1 / (NdotV + sqrt(a + b - a * b));
}

// Smith GGX G项，各项异性版本
// Derived G function for GGX
float smithG_GGX_aniso(float dotVN, float dotVX, float dotVY, float ax, float ay)
{
	return 1.0 / (dotVN + sqrt(pow(dotVX * ax, 2.0) + pow(dotVY * ay, 2.0) + pow(dotVN, 2.0)));
}


// GGX清漆几何项
// G GGX function for clearcoat
float G_GGX(float dotVN, float alphag)
{
		float a = alphag * alphag;
		float b = dotVN * dotVN;
		return 1.0 / (dotVN + sqrt(a + b - a * b));
}
```



### D. disney BSDF

当进入到离线渲染和路径追踪的全局光照时，BRDF就不够用了，因此拓展成了BSDF。

disney BSDF本质是金属BRDF、非金属BRDF、镜面BSDF三者的混合型模型。

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-16148202bf65d3c90f71452dc56d3449_1440w.jpg)



## 三、法线分布函数NDF

### A.物理渲染与建模尺度

图形学中，对几何体外观的建模，总会假设一定的建模尺度和观察尺度：

- **宏观尺度（Macroscale），** 几何体通过三角形网格进行建模, 由顶点法线（Vertex Normal）提供每顶点法线信息
- **中尺度（Mesoscale），** 几何体通过纹理进行建模，由法线贴图（Normal Map）提供每像素法线信息
- **微观尺度（Microscale），** 几何体通过BRDF进行建模，由粗糙度贴图（Roughness Map）配合法线分布函数，提供每亚像素（subpixel）法线信息

传统光照模型一般只建模到中尺度，并且使用的NDF不满足能量守恒。pbr渲染工作流中采用粗糙度贴图+微平面归一化的NDF函数将物体在微观尺度进行了建模。



### B.法线分布函数与微平面理论

微平面模型主要用来描述微平面法线m的统计分布，该分布由法线分布函数NDF定义。

- 微平面的法线分布函数**D(m)**描述了微观表面上的表面法线**m**的统计分布。给定以**m**为中心的无穷小立体角 $d\omega_m$和无穷小宏观表面区域$dA$ ，则 $D(m)d\omega_mdA$是相应微表面部分的总面积，其法线位于指定的立体角内。因此NDF的本质是一个密度函数，单位为1/球面度（1/steradians）。
- 从直觉上来说，NDF就像是微平面法线分布的直方图（histogram）。 它在微平面法线更可能指向的方向上具有更高的值。大多数表面都具有在宏观表面法线**n**处显示出很强的法线分布峰值。
- 若以函数输入和输出的角度来看NDF，则其输入为**微表面粗糙度**（微表面法线集中程度）和宏观法线与视线的中间矢量（**微表面法线方向**），输出为此方向上的微表面法线占比。
- 一般我们用宏观表面的半矢量**h**来表示微观表面法线**m**，因为仅**m = h**的表面点的朝向才会将光线**l**反射到视线**v**的方向，其他朝向的表面点对BRDF没有贡献（无法进入视线方向就无法看到）。

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-f373bc7fddf0a021c4f3fdd6e0346fa5_1440w.jpg)



### C.法线分布函数的基本性质

一个基于物理的的微平面法线分布的基本性质，可以总结如下：

**1. 微平面法线密度始终为非负值:**

![[公式]](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cequation-1602744441202.svg)

**2. 微表面的总面积始终不小于宏观表面总面积:**

![[公式]](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cequation-1602744441261.svg)

**3. 任何方向上微观表面投影面积始终与宏观表面投影面积相同:**

![[公式]](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cequation-1602744441270.svg)

**4. 若观察方向为法线方向，则其积分可以归一化。即v = n时，有**：

![[公式]](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cequation-1602744441262.svg)

其中宏观表面片元面积规定为1，即将微表面区域投影到宏观表面区域，得到的宏观表面面积为1.

如下图所示，$n\cdot m$表示微平面法向量m和宏观法向量n的夹角余弦，由于n垂直于宏观平面，该余弦值也等于将微表面区域投影至宏观表面的夹角余弦。

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-5db7b017cb8509471d6951af179fb0bf_1440w.jpg)



### D.各向同性NDF

各向同性的法线分布函数围绕宏观表面法线n轴旋转对称，相当于降维成平面？

最常用的NDF是GGX分布，因为其分布具有形状不变性，其余像GTR分布都没有。

形状不变性（shape-invariant）是一个合格的法线分布函数需要具备的重要性质。具有形状不变性（shape-invariant）的法线分布函数，可以用于推导该函数的归一化的各向异性版本，并且可以很方便地推导出对应的遮蔽阴影项G。

- 对于形状不变的NDF，缩放粗糙度参数相当于通过倒数拉伸微观几何,如下图所示。

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-0c09bfe3226e7305966e0f550b90fb93_1440w.jpg)

- 关于形状不变性的好处，可以总结为：

- - 方便推导出该NDF归一化的各向异性版本
  - 方便推导出遮蔽阴影项 Smith G
  - 方便基于NDF或可见法线分布推导其重要性采样
  - 对于Smith G，可用低维函数或表格处理所有粗糙度和各向异性



### 四、几何函数相关

#### A.几何函数定义与属性

定义：一个0-1的标量，描述了微平面的自遮挡属性，表示了具有半矢量法线的微平面（microfacet）中，同时被入射方向和反射方向可见（没有被遮挡的）的比例，即未被遮挡的m= h微表面的百分比。几何函数（Geometry Function）即是对**能顺利完成对光线的入射和出射交互**的微平面概率进行建模的函数。

- 在部分游戏引擎和文献中，几何函数G(l,v,h)和分母中的校正因子4（n·l）（n·v）会合并为可见性项（The Visibility Term），Vis项，简称V项。其也经常作为几何函数的代指：

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-850dc05e080cb3698b002c8a237cbfd5_1440w.jpg)

- 通常，除了近掠射角或非常粗糙的表面，几何函数对BRDF的形状影响相对较小，但对于BRDF保持能量守恒而言，几何函数至关重要。
- 几何函数取决于微表面的细节，并且很少有精确的表达式。很多情况下，各类文献会使用各种统计模型和简化假设推导出近似值。



#### B.微平面理论与几何函数的关系

##### 1.微平面理论到几何函数

几何函数具有两种主要形式：G1和G2，其中：

- G1为微平面在单个方向（光照方向L或观察方向V）上可见比例，一般代表遮蔽函数（masking function）或阴影函数（shadowing function）
- G2为微平面在光照方向L和观察方向V两个方向上可见比例，一般代表联合遮蔽阴影函数（joint masking-shadowing function）
- 在实践中，G2由G1推导而来
- 默认情况下，microfacet BRDF中使用的几何函数代指G2

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-4d7971c6d8ce60a6e5729024887f1b05_1440w.jpg)

可见微平面的投影面积之和等于宏观表面的投影面积。我们可以通过定义遮蔽函数（masking function）G1(m,v)来对其进行数学表达，它给出了沿着视图向量v可见的具有法线m的微平面的比率。

G1(m, v)D(m)(v · m)+在球体上的积分然后给出投影到垂直于v的平面上的宏观表面的面积：

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-049def263fc4890cfda46967222b5900_1440w.jpg)

几何函数与法线分布函数作为Microfacet Specular BRDF中的重要两项，两者之间具有紧密的联系：

**几何函数的解析形式的确认依赖于法线分布函数。** 在微平面理论中，通过可见微平面的投影面积之和等于宏观表面的投影面积的恒等式，选定法线分布函数，并选定几何函数的微表面模型，就可以唯一确认几何函数的准确形式。在选定几何函数的模型后（一般为Smith），几何函数的解析形式的确认则由对应的法线分布函数决定。

由于几何函数只是一个遮蔽占比，如果不确定微表面模型只有NDF函数，那将有无数个几何函数满足NDF函数的约束，因为NDF没有完全指定微表面，只给出了微表面朝某个方向的百分比。如下所示，微表面轮廓的选择可对所得BRDF的形状产生强烈影响。

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-74fd18e9eddafc6ea18cd43852ee073d_1440w.jpg)



**法线分布函数需要结合几何函数，得到有效的法线分布强度。** 单纯的法线分布函数的输出值并不是能产生有效反射的法线强度，因为光线的入射和出射会被微平面部分遮挡，即并不是所有朝向m=h的微表面，能在给定光照方向L和观察方向V时可以顺利完成有效的反射。几何函数即是对能顺利完成入射和出射的微平面概率进行建模的函数。法线分布函数需要结合几何函数，得到最终对microfacet BRDF能产生贡献的有效法线分布强度。

##### 2.微表面模型的选择

选择了合适的微表面模型，加上(1)的等式约束，就可以确定遮蔽函数，输出一个遮蔽百分比。基于物理的微表面遮蔽模型有Smith遮蔽函数和V腔遮蔽函数，smith最常用。

Heitz还证明了Smith遮蔽函数是唯一既遵循公式（1），又具有法线遮蔽独立性（normal-masking independence）便利特性的函数。且Smith遮蔽函数具有比Cook-Torrance使用的V腔遮蔽函数（V-cavity masking function）更好地匹配真实世界的反射现象。

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-13e64081024b7006b835e143751fa0ac_1440w.jpg)

##### 3.smith遮蔽函数的性质

Smith G1函数的形式如下：

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-eceb6c0ee6dc313b8b76475b4eded283_1440w.jpg)

其中,χ+(x)表示正特征函数：

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-eb5b126dfb1f258153e4f5e8ed2d922f_1440w.jpg)

- ![[公式]](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cequation-1603097331008.svg) 表示微表面斜率上的积分（integral over the slopes of the microsurface），其表达式为：

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-72fae8e3b8b622d21def7ecf44fee6f0_1440w.jpg)

其中

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-f3388972790c319438803c979273a6f8_1440w.jpg)

为视图方向上斜率的1D分布。

- ![[公式]](https://www.zhihu.com/equation?tex=P%5E%7B22%7D%5Cleft+%28+x_%7B%5Ctilde%7Bm%7D%7D%2Cy_%7B%5Ctilde%7Bm%7D%7D+%5Cright+%29++) 为微表面的斜率分布（distribution of slopes of the microsurface）。
- 而 ![[公式]](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cequation-1603097388517.svg) 为与法线 ![[公式]](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cequation-1603097388524.svg) 相关的斜率：

 ![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-7d017d40b2394a2fef2f133743ce5317_1440w.jpg)

- 斜率分布与法线分布的关系为：

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-05f4034f9c8418810008afd7908cd723_1440w.jpg)

?$\theta_m$和$\theta_o$含义是？

$\theta_o$是出射方向与微表面法线方向的夹角

##### 4.smith联合遮蔽-阴影函数

即由G1推到G2，主要有分离型、高度相关型、方向相关型、高度-方向相关型。

###### 4.1分离的遮蔽-阴影函数

该形式遮蔽和阴影相互独立，分别计算G1相乘即可：

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-8426524942fe1b9596c60b1a53cb3ef1_1440w.jpg)

该方法最常用，但会多估算阴影。

#### C.多重散射微平面BRDF

通过G2几何遮蔽函数，BRDF考虑了遮蔽和阴影，但没有考虑微平面之间的多表面反射和互反射，业界主流的BRDF暂时都有这个限制，该限制在粗糙度较高的金属表面会造成较大的能量损失。

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-6d63d7230c709d54968cbd3c521b8b4d_1440w.jpg)

图 由于单次散射，反射随着粗糙度增加而变暗

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-3e3846f339578718babdb987c5636879_1440w.jpg)

图 多散射则是能量守恒的

Sony ImageWork的Kulla和Conty[Kulla 2017]在SIGGRPAPH 2017上中提出了一项新的技术方案，创建一个模拟多次反射表面反射的附加BRDF波瓣，作为能量补偿项（Energy Compensation Term）：

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-f3f9527c2df3df7540cf3d16c0d562c4_1440w.jpg)

增加了能量补偿后的BRDF可以很好的解决高粗糙度下的能量损失问题。

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-5572141744bf06e2b2f4b1c0f3c6d7af_1440w.jpg)

图 GGX单散射

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-560ea37ed6522caa5e2d3dfc94580b00_1440w.jpg)

图 GGX单散射+能量补偿

#### D.从法线分布函数导出smith遮蔽函数

根据不同的法线分布函数，推导出smith遮蔽函数Λ的解析形式。

##### GGX法线分布的Λ函数

GGX法线分布函数具备形状不变性，其Smith遮蔽函数对应的Λ解析形式相对简单，为：

![img](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cv2-8fd2c68aea564c34d21e8ec9065e8e20_1440w.jpg)

其中， ![[公式]](C:%5CUsers%5Czca%5CDesktop%5Czca%5Clearnopengl%5Cpbr.assets%5Cequation-1603260699344.svg)

GGX分布和GGX –Smith遮蔽阴影函数的组合，是目前游戏和电影业界主流的方案。且业界一直致力于优化两者的组合。