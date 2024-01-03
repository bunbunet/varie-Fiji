import ij.gui.PolygonRoi
import ij.plugin.frame.RoiManager

def roiManager = RoiManager.getInstance()
roiManager.getRoisAsArray().each { roi ->
    ij.IJ.log(roi.getName() + ': ' + roi.getPolygon().npoints)
}