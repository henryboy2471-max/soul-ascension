extends SceneTree
# Compression error of the VRAM-compressed Cantor frames vs their source PNGs (run with the frames in VRAM mode):
#   godot --headless --path . --script res://tools/texture_error.gd
func _initialize() -> void:
 for set in ["res://assets/enemies/hollow_cantor","res://assets/enemies/hollow_cantor/phase2"]:
  var worst_psnr=999.0
  var sum_mse=0.0
  var n=0
  var worst_alpha=0.0
  var compressed=0
  for f in DirAccess.get_files_at(set+"/frames"):
   if not f.ends_with(".png"): continue
   var tex=load(set+"/frames/"+f) as Texture2D
   var img=tex.get_image()
   if img.is_compressed():
    compressed+=1
    img.decompress()
   var src=Image.load_from_file(ProjectSettings.globalize_path(set+"/frames/"+f))
   src.convert(Image.FORMAT_RGBA8)
   img.convert(Image.FORMAT_RGBA8)
   var mse=0.0
   var cnt=0
   for y in range(0,src.get_height(),3):    # sample every 3rd pixel in both directions (get_pixel: robust to block-padded row strides)
    for x in range(0,src.get_width(),3):
     var ps=src.get_pixel(x,y)
     var pd=img.get_pixel(x,y)
     for c in range(3):
      var d=(ps[c]-pd[c])*255.0*ps.a
      mse+=d*d
     cnt+=3
     worst_alpha=maxf(worst_alpha,absf(ps.a-pd.a))
   mse/=float(cnt)
   var p=99.0 if mse==0.0 else 10.0*log(255.0*255.0/mse)/log(10.0)
   worst_psnr=minf(worst_psnr,p)
   sum_mse+=mse
   n+=1
  var mean_psnr=10.0*log(255.0*255.0/(sum_mse/float(n)))/log(10.0)
  print("%s: %d frames (%d compressed in memory) | mean PSNR %.1f dB, worst frame %.1f dB | worst alpha error %.1f%%" % [set,n,compressed,mean_psnr,worst_psnr,worst_alpha*100.0])
 quit()
