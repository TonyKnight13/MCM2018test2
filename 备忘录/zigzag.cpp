/* 
    对矩阵进行zigzag扫描，m表示扫描矩阵，n表示矩阵维度,v为扫描后得到的定长向量 
*/  
void zigzag(CvMat* m,int n,vector<double> &v)  
{  
    int i,j,s,dir,squa;  
    i=j=0;  
    dir=0;  
    s=0;  
    squa=n*n;  
    //扫描  
    while(s<squa)  
    {  
        switch(dir)  
        {  
        case 0:  
            v.push_back(cvmGet(m,i,j));  
            j++;  
            if(0==i)  
                dir=1;  
            if(n-1==i)  
                dir=3;  
            break;  
        case 1:  
            v.push_back(cvmGet(m,i,j));  
            i++;  
            j--;  
            if(n-1==i)//这里有if和else,注意这里的逻辑和上面两个if的逻辑有区别的  
                dir=0;  
            else if(0==j)  
                dir=2;  
            break;  
        case 2:  
            v.push_back(cvmGet(m,i,j));  
            i++;  
            if(0==j)  
                dir=3;  
            if(n-1==j)  
                dir=1;  
            break;  
        case 3:  
            v.push_back(cvmGet(m,i,j));  
            i--;  
            j++;  
            if(n-1==j)  
                dir=2;  
            else if(0==i)  
                dir=0;  
            break;  
        default:  
            break;  
        }  
        s++;  
    }  
}  