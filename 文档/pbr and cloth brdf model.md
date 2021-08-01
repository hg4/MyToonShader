**PBR**

**概念：**基于物理的渲染，表现为三个特点：

1.基于物理的**渲染方程**$L_o(p,\omega_o) = L_e + \int\limits_{\Omega} f_r(p,\omega_i,\omega_o) L_i(p,\omega_i) n \cdot \omega_i  d\omega_i$

2.基于**微平面理论**。

3.符合**能量守恒**。

离线渲染中pbr的典型应用场景：ray tracing（递归求解渲染方程）

实时渲染中，disney经过研究对pbr的基于物理部分进行了简化，提出了一套标准和流程使pbr可以被实时应用，目前已经广泛应用在工业界游戏制作中。



**使用pbr的好处：**可以在实时渲染中近似地模拟真实物理世界的观感，达不到离线渲染的水平，但远比原先的phong光照模型好得多。



![img](https://img-blog.csdn.net/20160719173042002)

**如何在实时渲染中使用pbr？：**首先要能在实时中满足pbr的三个特点。

1.基于物理渲染方程，我们只使用简化的反射方程部分$L_o(p,\omega_o) = \int\limits_{\Omega} f_r(p,\omega_i,\omega_o) L_i(p,\omega_i) n \cdot \omega_i  d\omega_i$

$f_r(p,\omega_i,\omega_o)$:BxDF，一般是BRDF双向反射分布函数，描述了光所交互物体的**材质**。功能是简单来说就是和位置和入射方向有关的出射光线的能量分布占比。一般会分成两个diffuse和specular的brdf模拟不同项。实时渲染中常用的brdf是一个较为通用的模型，可以通过调参调出不同的材质，一般引入一个金属度metallic对金属brdf和非金属brdf进行混合，方便实现不同材质。

$L_i(p,\omega_i)$:入射光的radiance。

n·wi:入射光与法线夹角。

$L_o(p,\omega_o)$:从wo方向出射的radiance。

如果我们已知了BRDF，剩下的就是怎么解积分，如果入射光有限，那么积分就不用解了，因此如果只是想在实时渲染中用有限光源获得稍微好一点的效果，找个brdf然后用渲染方程把原先的光照模型替代掉就行了。

但是由于只解了一次渲染方程，还是只有直接光照，效果也不会很真实，这里就需要用到**IBL（image based lighting）**来模拟间接或者全局光照的效果。

IBL可以简单理解成一个记录了环境近似的全局光照的贴图，并不是真的全局光照只是上面提到的反射方程积分的一个预计算，用的时候只要采样贴图然后叠加到出射的radiance上就行，怎么来的怎么算的具体不展开可以当一个黑箱先用。

2.基于微平面理论。微平面理论简单说来就是物体表面微观上是凹凸不平的，我们平时用的宏观法线并不能代表表面的真实情况，要引入微平面法线，当确定了视线方向V和光线方向L后，只有表面存在朝着$\bold H=\frac{\bold V+\bold L}{|\bold V+\bold L|} $方向的微平面法线时，才有部分光线能进入我们的眼中。我们引入一个粗糙度roughness来对微平面进行建模，roughness含义是微表面法线和宏观法线的差异程度，越粗糙的表面微表面法线和宏观法线的差异越大，这在直观上也易于理解。

![img](https://pic2.zhimg.com/80/v2-5fe364fb35d463da3008ef48ce69fb91_720w.jpg)

3.能量守恒，这个只要满足前两点然后使用的brdf不要过于经验型，自然就会成立。



**brdf材质详解：**

一般的通用brdf都是分成diffuse brdf和specular brdf两项：
$$
f_r = (1-F)f_{diffuse}+f_{specular}
$$
![img](https://pic3.zhimg.com/80/v2-b855ab10a0b290f023898332e0360dce_720w.jpg)

diffuse brdf：描述与材质交互时表面漫反射的分布，但由于漫反射是由光进入介质中发生折射、吸收、散射表现出来的最终现象，对漫反射进行正确描述是很困难的，因此这部分的brdf比较常用的是经验模型。

Lambert模型
$$
f_d=\frac{c}{\pi}
$$
disney diffuse模型

![[公式]](https://www.zhihu.com/equation?tex=f_d+%3D+%5Cfrac%7BbaseColor%7D%7B%5Cpi+%7D%281%2B%28F_%7BD90%7D+-1%29%281-cos%5Ctheta+_l%29%5E%7B5%7D%29%281+%2B+%28F_%7BD90%7D-1%29%281-cos%5Ctheta+_v%29%5E5%29++%5C%5C)

specular brdf：

通用的cook-torrance模型
$$
f_{cook-torrance} = \frac{DFG}{4(\omega_o \cdot n)(\omega_i \cdot n)}
$$
分子的DFG三项分别为：

D法线分布函数，描述了微平面法线的统计分布情况，可以理解成输入一个法线方向和表面粗糙度，输出在这个表面该法线的占比。

F菲涅尔项，描述了反射光线在入射光线中的能量占比，入射光一部分发生反射、一部分发生折射。

G几何遮蔽项，描述了光线能不被微表面遮挡顺利完成入射出射的概率，因为微表面是凹凸不平的光线有可能在传播过程中被挡住。

选择好DFG三项的具体函数，specular brdf就被确定，加上之前提到的metallic+roughness的参数调整，就可以做出各种各样的材质，在shader中的计算公式就是按渲染方程结合这个通用的brdf材质模型。

![猴子都能看懂的PBR（才怪）](https://pic1.zhimg.com/v2-c48b06d25b464687053144ab73fc92d3_1440w.jpg?source=172ae18b)

特定材质模型（以布料为例）

<img src="C:\Users\Admin\AppData\Roaming\Typora\typora-user-images\image-20210127164442508.png" alt="image-20210127164442508" style="zoom: 67%;" /><img src="C:\Users\Admin\AppData\Roaming\Typora\typora-user-images\image-20210127164927773.png" alt="image-20210127164927773" style="zoom: 67%;" />

![image-20210129131646462](pbr%20and%20cloth%20brdf%20model.assets/image-20210129131646462.png)

![image-20210129132414420](pbr%20and%20cloth%20brdf%20model.assets/image-20210129132414420.png)

特定的材质就要使用为之设计的特定的brdf。布料织物容易发生较多的次表面散射，有其特有的光照反射模型。以天鹅绒为例，它的高光位置不是灯光和视线的正对区域，而是边缘位置。

![img](https://pic1.zhimg.com/80/v2-47aa7fbe6ffe10c9d74a069282b4dfac_720w.jpg)

diffuse brdf：基于Lambert模型结合次表面散射项。
$$
f_d=\frac{c}{\pi}×\frac{n\cdot l+w}{(1+w)^2}(c_{subsurface}+n\cdot l)
$$
specular brdf：
$$
f_s=\frac{FD}{4(n\cdot l+n\cdot v -(n\cdot l)(n\cdot v))}
$$
其中F为菲涅尔项，D为法线分布函数。

