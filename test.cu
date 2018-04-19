// test.cu
//
// demo of using thrust library to parse a large '|' delimited file.
//
// Build instructions at a Visual Studio 2010 Command Prompt: [CUDA 8.0 in the path here]
// nvcc -O3 -arch=sm_21 -lcuda test.cu -o test
// 
// Run with 'test.exe' <ENTER>

#include <iostream>
#include <string>
#include <thrust/device_vector.h>
#include <thrust/copy.h>
#include <thrust/count.h>
#include <ctime>
#include "nvparse.h"

#ifdef _WIN64
#define atoll(S) _atoi64(S)
#include <windows.h>
#else
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#endif

int main()
{
    char * filename = "lineitem_small.tbl";

	std::clock_t start1 = std::clock();

    // get filesize
    FILE* f = fopen(filename, "r" );
    if (!f) {
        printf("Unable to open file %s \n",filename);
        exit(1);
    }
    fseek(f, 0, SEEK_END);
    long fileSize = ftell(f);
    fclose(f);

    // reserve filesize char vector on GPU
    thrust::device_vector<char> dev(fileSize);

#ifdef _WIN64
    // fast read of file using mapping
	HANDLE file = CreateFileA(filename, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL);
    assert(file != INVALID_HANDLE_VALUE);

    HANDLE fileMapping = CreateFileMapping(file, NULL, PAGE_READONLY, 0, 0, NULL);
    assert(fileMapping != INVALID_HANDLE_VALUE);
 
    LPVOID fileMapView = MapViewOfFile(fileMapping, FILE_MAP_READ, 0, 0, 0);
    auto fileMapViewChar = (const char*)fileMapView;
    assert(fileMapView != NULL);

    thrust::copy(fileMapViewChar, fileMapViewChar+fileSize, dev.begin());
#else
    // non-Windows read of file via mapping
    struct stat sb;
	char *p;
	int fd;
    fd = open ("lineitem.tbl", O_RDONLY);
	if (fd == -1) {
		perror ("open");
		return 1;
	}
	if (fstat (fd, &sb) == -1) {
		perror ("fstat");
		return 1;
	}
	if (!S_ISREG (sb.st_mode)) {
		fprintf (stderr, "%s is not a file\n", "lineitem.tbl");
		return 1;
	}
	p = (char*)mmap (0, fileSize, PROT_READ, MAP_SHARED, fd, 0);
	if (p == MAP_FAILED) {
		perror ("mmap");
		return 1;
	}
	if (close (fd) == -1) {
		perror ("close");
		return 1;
	}
	thrust::copy(p, p+fileSize, dev.begin());
#endif

    // count lines in file
    int cnt = thrust::count(dev.begin(), dev.end(), '\n');
    std::cout << "There are " << cnt << " total lines in the file" << "\n";

    // char locations for line breaks in vector 
    thrust::device_vector<int> dev_pos(cnt+1);
    dev_pos[0] = -1;
    thrust::copy_if(thrust::make_counting_iterator((unsigned int)0),        // count from start of file
                    thrust::make_counting_iterator((unsigned int)fileSize), // until end of file
                    dev.begin(),        // stencil pred(*stencil)==true causes *dev_pos[] to get location of line break
                    dev_pos.begin()+1,  // position of line break character
                    is_break());        // predicate

    // 11 columns of 15 characters
    thrust::device_vector<char> dev_res1(cnt*15);
    thrust::fill(dev_res1.begin(), dev_res1.end(), 32);
    thrust::device_vector<char> dev_res2(cnt*15);
    thrust::fill(dev_res2.begin(), dev_res2.end(), 32);
    thrust::device_vector<char> dev_res3(cnt*15);
    thrust::fill(dev_res3.begin(), dev_res3.end(), 32);
    thrust::device_vector<char> dev_res4(cnt*15);
    thrust::fill(dev_res4.begin(), dev_res4.end(), 32);
    thrust::device_vector<char> dev_res5(cnt*15);
    thrust::fill(dev_res5.begin(), dev_res5.end(), 32);
    thrust::device_vector<char> dev_res6(cnt*15);
    thrust::fill(dev_res6.begin(), dev_res6.end(), 32);
    thrust::device_vector<char> dev_res7(cnt*15);
    thrust::fill(dev_res7.begin(), dev_res7.end(), 32);
    thrust::device_vector<char> dev_res8(cnt*15);
    thrust::fill(dev_res8.begin(), dev_res8.end(), 32);
    thrust::device_vector<char> dev_res9(cnt);
    thrust::fill(dev_res9.begin(), dev_res9.end(), 32);
    thrust::device_vector<char> dev_res10(cnt);
    thrust::fill(dev_res10.begin(), dev_res10.end(), 32);
    thrust::device_vector<char> dev_res11(cnt*10);
    thrust::fill(dev_res11.begin(), dev_res11.end(), 32);

    // 11 pointers to column data
    thrust::device_vector<char*> dest(11);
    dest[0] = thrust::raw_pointer_cast(dev_res1.data());
    dest[1] = thrust::raw_pointer_cast(dev_res2.data());
    dest[2] = thrust::raw_pointer_cast(dev_res3.data());
    dest[3] = thrust::raw_pointer_cast(dev_res4.data());
    dest[4] = thrust::raw_pointer_cast(dev_res5.data());
    dest[5] = thrust::raw_pointer_cast(dev_res6.data());
    dest[6] = thrust::raw_pointer_cast(dev_res7.data());
    dest[7] = thrust::raw_pointer_cast(dev_res8.data());
    dest[8] = thrust::raw_pointer_cast(dev_res9.data());
    dest[9] = thrust::raw_pointer_cast(dev_res10.data());
    dest[10] = thrust::raw_pointer_cast(dev_res11.data());

    // which field to select / parse
    thrust::device_vector<unsigned int> ind(11); //fields positions
    ind[0] = 0;
    ind[1] = 1;
    ind[2] = 2;
    ind[3] = 3;
    ind[4] = 4;
    ind[5] = 5;
    ind[6] = 6;
    ind[7] = 7;
    ind[8] = 8;
    ind[9] = 9;
    ind[10] = 10;

    // field max length
    thrust::device_vector<unsigned int> dest_len(11); //fields max lengths
    dest_len[0] = 15;
    dest_len[1] = 15;
    dest_len[2] = 15;
    dest_len[3] = 15;
    dest_len[4] = 15;
    dest_len[5] = 15;
    dest_len[6] = 15;
    dest_len[7] = 15;
    dest_len[8] = 1;
    dest_len[9] = 1;
    dest_len[10] = 10;

    // count of fields to parse from each line
    thrust::device_vector<unsigned int> ind_cnt(1); //fields count
    ind_cnt[0] = 10;

    // field separator across line
    thrust::device_vector<char> sep(1);
    sep[0] = '|';

    // split file by line breaks and field separators
    thrust::counting_iterator<unsigned int> begin(0);
    parse_functor ff((const char*)thrust::raw_pointer_cast(dev.data()), // raw file characters
                     (char**)thrust::raw_pointer_cast(dest.data()),     // array of pointers to dest (column) buffers
                     thrust::raw_pointer_cast(ind.data()),              // mapping
                     thrust::raw_pointer_cast(ind_cnt.data()),          // count of columns to parse
                     thrust::raw_pointer_cast(sep.data()),              // separator character
                     thrust::raw_pointer_cast(dev_pos.data()),          // 
                     thrust::raw_pointer_cast(dest_len.data()));
    thrust::for_each(begin, begin + cnt, ff); // now dev_pos vector contains the indexes of new line characters

	std::cout<< "Split out text fields in " <<  ( ( std::clock() - start1 ) / (double)CLOCKS_PER_SEC ) << '\n';

    // parse binary integer results from columns 1-5
    thrust::device_vector<long long int> d_int1(cnt);
    thrust::device_vector<long long int> d_int2(cnt);
    thrust::device_vector<long long int> d_int3(cnt);
    thrust::device_vector<long long int> d_int4(cnt);
    thrust::device_vector<long long int> d_int5(cnt);
    ind_cnt[0] = 15;
    gpu_atoll atoll_ff1( (const char*)thrust::raw_pointer_cast(dev_res1.data()),
                         (long long int*)thrust::raw_pointer_cast(d_int1.data()),
                         thrust::raw_pointer_cast(ind_cnt.data()));
    thrust::for_each(begin, begin + cnt, atoll_ff1);
    gpu_atoll atoll_ff2( (const char*)thrust::raw_pointer_cast(dev_res2.data()),
                         (long long int*)thrust::raw_pointer_cast(d_int2.data()),
                         thrust::raw_pointer_cast(ind_cnt.data()));
    thrust::for_each(begin, begin + cnt, atoll_ff2);
    gpu_atoll atoll_ff3( (const char*)thrust::raw_pointer_cast(dev_res3.data()),
                         (long long int*)thrust::raw_pointer_cast(d_int3.data()),
                         thrust::raw_pointer_cast(ind_cnt.data()));
    thrust::for_each(begin, begin + cnt, atoll_ff3);
    gpu_atoll atoll_ff4( (const char*)thrust::raw_pointer_cast(dev_res4.data()),
                         (long long int*)thrust::raw_pointer_cast(d_int4.data()),
                         thrust::raw_pointer_cast(ind_cnt.data()));
    thrust::for_each(begin, begin + cnt, atoll_ff4);
    gpu_atoll atoll_ff5( (const char*)thrust::raw_pointer_cast(dev_res5.data()),
                         (long long int*)thrust::raw_pointer_cast(d_int5.data()),
                         thrust::raw_pointer_cast(ind_cnt.data()));
    thrust::for_each(begin, begin + cnt, atoll_ff5);
    for(int i = cnt-2; i < cnt; i++)
        std::cout << "Line: " << i << " " << d_int1[i] << " " << d_int2[i] << " " << 
                         d_int3[i] << " " << d_int4[i] << " " << d_int5[i] << "\n";
    std::cout <<  "\n";

    // parse binary double results for columns 6 7 8
    thrust::device_vector<double> d_double6(cnt);
    thrust::device_vector<double> d_double7(cnt);
    thrust::device_vector<double> d_double8(cnt);
    gpu_atof atof_ff6((const char*)thrust::raw_pointer_cast(dev_res6.data()),
                      (double*)thrust::raw_pointer_cast(d_double6.data()),
                      thrust::raw_pointer_cast(ind_cnt.data()));
    thrust::for_each(begin, begin + cnt, atof_ff6);
    gpu_atof atof_ff7((const char*)thrust::raw_pointer_cast(dev_res7.data()),
                      (double*)thrust::raw_pointer_cast(d_double7.data()),
                      thrust::raw_pointer_cast(ind_cnt.data()));
    thrust::for_each(begin, begin + cnt, atof_ff7);
    gpu_atof atof_ff8((const char*)thrust::raw_pointer_cast(dev_res8.data()),
                      (double*)thrust::raw_pointer_cast(d_double8.data()),
                      thrust::raw_pointer_cast(ind_cnt.data()));
    thrust::for_each(begin, begin + cnt, atof_ff8);
    std::cout.precision(10);
    for(int i = cnt-2; i < cnt; i++)
        std::cout << "Line: " << i << " " << d_double6[i] << " " << d_double7[i] << " " << d_double8[i] << "\n";
    std::cout.flush();

    // timing status
	std::cout<< "And parsed 5 x int and 3 x double columns in " <<  ( ( std::clock() - start1 ) / (double)CLOCKS_PER_SEC ) << '\n';

    // dump text results for a few lines - remember that we are dealing with rows rows of 15 characters
    // hence the i*15 + c to calculate the character to (slowly) retreive below.
    for(int i = 0; i < 15; i++) {
        std::cout << "Line " << i << ":";
        for(int c=0; c<15;c++)
            std::cout << dev_res1[i*15+c];
        std::cout << "|";
        for(int c=0; c<15;c++)
            std::cout << dev_res2[i*15+c];
        std::cout << "|";
        for(int c=0; c<15;c++)
            std::cout << dev_res3[i*15+c];
        std::cout << "|";
        for(int c=0; c<15;c++)
            std::cout << dev_res4[i*15+c];
        std::cout << "|";
        for(int c=0; c<15;c++)
            std::cout << dev_res5[i*15+c];
        std::cout << "|";
        for(int c=0; c<15;c++)
            std::cout << dev_res6[i*15+c];
        std::cout << "\n";
    }

    return 0;
}