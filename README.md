# MeshTools
Collection of Swift tools to help make objects for 3D printing

No texture coordinates!  The intent here is create an object for 3D printing, as opposed to displaying with SceneKit.

The Mesh class creates two Sets: One for edges that are used only once, and one for edges that are used twice.  An attempt to use an edge a third time will cause an error.  This is the primary tool for verifying the quality of a mesh.