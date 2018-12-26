# FigLay MATLAB
### *Figure layout planning in `Inkscape` & `MATLAB` for easily-reproducible figures*  
This function is for planning figure layout in Inkscape (to produce tagged `.svg` files) before plotting sub panels in `MATLAB`.   
The reason I wrote this function was because of the manual labor of deciding the subplot positions in `MATLAB`.  
### Prerequisites  
* Basic usuage of `Inkscape` (customizing rectangles and `XML editors`)   
* `MATLAB` (so far I have been using `MATLAB R2016a`). I am unsure if earlier versions would have issues. 
### Inspirations  
The idea of using `Inkscape` to create a tagged `.svg` file is from the package in `python` called `FigureFirst`, which parses `.svg` file to read in axes position for `matplotlib`. Specifically, the github link is https://github.com/FlyRanch/figurefirst. I was inspired by this to create one for `MATLAB` users.
