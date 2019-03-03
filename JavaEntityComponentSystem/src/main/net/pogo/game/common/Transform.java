package net.pogo.game.common;

import android.opengl.Matrix;

/**
 * Created by blake on 20/05/17.
 */

public class Transform {

    public float [] matrix = new float[16];

    public void SetUnity()
    {
        Matrix.setIdentityM(matrix, 0);
    }

    public Transform()
    {
        SetUnity();
    }

    public void Translate(float x, float y, float z)
    {
        Matrix.translateM(matrix, 0 , x ,y, z);
    }

    public void Rotate(float angle, float x, float y, float z)
    {
        Matrix.rotateM(matrix, 0 , angle, x ,y, z);

    }

    public  void Scale(float scale)
    {
        Matrix.scaleM(matrix, 0, scale, scale, scale);
    }

    public float[] GetMatrix()
    {
        return matrix;
    }

}
